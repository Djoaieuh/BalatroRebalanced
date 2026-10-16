#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define MY_HIGHP_OR_MEDIUMP highp
#else
    #define MY_HIGHP_OR_MEDIUMP mediump
#endif

// Steamodded strips the mod prefix, so this is plain "empowered".
extern MY_HIGHP_OR_MEDIUMP vec2 empowered;          // x = tilt, y = real time (sent by the game)
extern MY_HIGHP_OR_MEDIUMP number empower_prog;     // 0 -> 1 during the reveal (sent by tarotTycoon.lua)

extern MY_HIGHP_OR_MEDIUMP number dissolve;
extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec4 texture_details;
extern MY_HIGHP_OR_MEDIUMP vec2 image_details;
extern bool shadow;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_2;

vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv)
{
    if (dissolve < 0.001) {
        return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, shadow ? tex.a*0.3: tex.a);
    }

    float adjusted_dissolve = (dissolve*dissolve*(3. - 2.*dissolve))*1.02 - 0.01;

    float t = time * 10.0 + 2003.;
    vec2 floored_uv = (floor((uv*texture_details.ba)))/max(texture_details.b, texture_details.a);
    vec2 uv_scaled_centered = (floored_uv - 0.5) * 2.3 * max(texture_details.b, texture_details.a);

    vec2 field_part1 = uv_scaled_centered + 50.*vec2(sin(-t / 143.6340), cos(-t / 99.4324));
    vec2 field_part2 = uv_scaled_centered + 50.*vec2(cos( t / 53.1532),  cos( t / 61.4532));
    vec2 field_part3 = uv_scaled_centered + 50.*vec2(sin(-t / 87.53218), sin(-t / 49.0000));

    float field = (1.+ (
        cos(length(field_part1) / 19.483) + sin(length(field_part2) / 33.155) * cos(field_part2.y / 15.73) +
        cos(length(field_part3) / 27.193) * sin(field_part3.x / 21.92) ))/2.;
    vec2 borders = vec2(0.2, 0.8);

    float res = (.5 + .5* cos( (adjusted_dissolve) / 82.612 + ( field + -.5 ) *3.14))
    - (floored_uv.x > borders.y ? (floored_uv.x - borders.y)*(5.5*(1.-adjusted_dissolve)) : 0.)
    - (floored_uv.y > borders.y ? (floored_uv.y - borders.y)*(5.5*(1.-adjusted_dissolve)) : 0.)
    - (floored_uv.x < borders.x ? (borders.x - floored_uv.x)*(5.5*(1.-adjusted_dissolve)) : 0.)
    - (floored_uv.y < borders.x ? (borders.x - floored_uv.y)*(5.5*(1.-adjusted_dissolve)) : 0.);

    if (tex.a > 0.01 && burn_colour_1.a > 0.01 && !shadow && res < adjusted_dissolve + 0.8*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
        if (!shadow && res < adjusted_dissolve + 0.5*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
            tex.rgba = burn_colour_1.rgba;
        } else if (burn_colour_2.a > 0.01) {
            tex.rgba = burn_colour_2.rgba;
        }
    }

    return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, res > adjusted_dissolve ? (shadow ? tex.a*0.3: tex.a) : .0);
}

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p){
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0 - 2.0*f);
    return mix(mix(hash(i),                 hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p){
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++){ v += a*noise(p); p *= 2.0; a *= 0.5; }
    return v;
}

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 tex = Texel(texture, texture_coords);
    vec2 uv = (((texture_coords)*(image_details)) - texture_details.xy*texture_details.ba)/texture_details.ba;

    float tilt = empowered.x;
    float t    = empowered.y;

    vec3 deep   = vec3(0.30, 0.03, 0.55);
    vec3 bright = vec3(0.90, 0.32, 1.00);
    vec3 hot    = vec3(1.00, 0.88, 1.00);

    // ---- reveal sweep: wavefront travels bottom -> top while empower_prog goes 0 -> 1
    float p      = empower_prog;
    float front  = p*1.6 - 0.3;
    float dist   = 1.0 - uv.y;                          // 0 at bottom, 1 at top
    float reveal = 1.0 - smoothstep(front - 0.25, front, dist);
    float edge   = exp(-pow((dist - front)*8.0, 2.0)) * (1.0 - p);

    // ---- 1. mild darkening: art stays readable, just moodier and purple-tinted
    float lum    = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    vec3 graded  = mix(tex.rgb, vec3(lum), 0.15) * vec3(0.78, 0.66, 0.92);
    vec2 cc      = (uv - 0.5) * vec2(1.0, 0.85);
    float vig    = smoothstep(0.3, 0.75, length(cc));
    graded       = mix(graded, deep*0.5, vig*0.3);
    tex.rgb      = mix(tex.rgb, graded, reveal);

    // ---- 2. low purple fire along the bottom edge only
    float h  = uv.y;                                    // 1 at the bottom
    float n1 = fbm(vec2(uv.x*5.0, uv.y*3.5 - t*1.2));
    float n2 = fbm(vec2(uv.x*9.0 + 5.0, uv.y*6.0 - t*2.0));
    float f  = clamp((n1*0.7 + n2*0.3) + (h - 0.70)*2.0 - 0.45, 0.0, 1.0);
    f        = smoothstep(0.10, 0.55, f);
    vec3 flameCol = mix(deep, bright, f) + hot * pow(f, 3.0) * 0.15;

    // ---- 3. faint energy veins
    vec2 vp     = uv*vec2(5.0, 7.0) + vec2(tilt*0.6, -t*0.35);
    float ridge = abs(fbm(vp) - 0.5);
    float vein  = smoothstep(0.035, 0.0, ridge);
    vein       *= 0.5 + 0.5*sin(t*3.0 + fbm(uv*3.0)*6.0);

    // ---- 4. pulsing rim glow
    float d   = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float rim = smoothstep(0.16, 0.0, d) * (0.7 + 0.3*sin(t*2.5));

    // ---- 5. rising stars / embers on the card
    vec2 g = uv*vec2(9.0, 13.0);
    g.y += t*1.6;
    vec2 id   = floor(g);
    vec2 cell = fract(g) - 0.5;
    float r   = hash(id);
    cell.x   -= sin(t*2.0 + r*6.28)*0.2;
    float ember = step(0.66, r) * smoothstep(0.12, 0.0, length(cell))
                * (0.5 + 0.5*sin(t*5.0 + r*20.0));

    vec3 add = flameCol*f*0.5 + bright*vein*0.32 + bright*rim*0.5 + hot*ember*0.9;
    add = add*reveal + hot*edge*0.7;

    tex.rgb += add * tex.a;
    return dissolve_mask(tex*colour, texture_coords, uv);
}

extern MY_HIGHP_OR_MEDIUMP vec2 mouse_screen_pos;
extern MY_HIGHP_OR_MEDIUMP float hovering;
extern MY_HIGHP_OR_MEDIUMP float screen_scale;

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    if (hovering <= 0.){
        return transform_projection * vertex_position;
    }
    float mid_dist = length(vertex_position.xy - 0.5*love_ScreenSize.xy)/length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy)/screen_scale;
    float scale = 0.2*(-0.03 - 0.3*max(0., 0.3-mid_dist))
                *hovering*(length(mouse_offset)*length(mouse_offset))/(2. -mid_dist);

    return transform_projection * vertex_position + vec4(0,0,0,scale);
}
#endif