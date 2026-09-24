// Overlay shader: drawn ON TOP of the normal card sprite (like foil is).
// It outputs only "light" (colour + alpha), so the card art underneath stays intact.

#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
	#define MY_HIGHP_OR_MEDIUMP highp
#else
	#define MY_HIGHP_OR_MEDIUMP mediump
#endif


extern MY_HIGHP_OR_MEDIUMP vec2 polished;   // must match the SMODS.Shader key and the file name
extern MY_HIGHP_OR_MEDIUMP number dissolve;
extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec4 texture_details;
extern MY_HIGHP_OR_MEDIUMP vec2 image_details;
extern bool shadow;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 burn_colour_2;

// ---------------------------------------------------------------
// Tuning knobs
// ---------------------------------------------------------------
const float SWEEP_PERIOD     = 2.5;   // seconds per full cycle
const float SWEEP_FRACTION   = 0.6;   // share of the cycle spent sweeping (the rest is a pause)
const float SWEEP_SLANT      = 0.55;  // slant of the shine band
const float SHINE_STRENGTH   = 0.85;  // opacity of the sweeping band (0..1)
const float HOTSPOT_STRENGTH = 0.20;  // soft highlight that follows tilt
const float RIM_BASE         = 0.40;  // always-on edge glint, so changed cards stay easy to spot
const float RIM_SWEEP        = 0.65;  // extra edge glint as the band passes

// Persistent "glass" look — always present, independent of the timed sweep,
// so the card reads as different material even during the sweep's downtime.
const float GLASS_STRENGTH   = 0.3;  // opacity of the static glassy sheen
const float GLASS_SLANT      = 0.4;   // slant of the static sheen band
const float GLASS_WIDTH      = 0.75;  // how soft/wide the band is
const float GLITTER_STRENGTH = 0.1;  // fine sparkle grain
const float GLITTER_SCALE    = 70.0;  // grain density

// ---------------------------------------------------------------
// dissolve_mask: verbatim from foil.fs
// ---------------------------------------------------------------
vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv)
{
    if (dissolve < 0.001) {
        return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, shadow ? tex.a*0.3: tex.a);
    }

    float adjusted_dissolve = (dissolve*dissolve*(3.-2.*dissolve))*1.02 - 0.01; //Adjusting 0.0-1.0 to fall to -0.1 - 1.1 scale so the mask does not pause at extreme values

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
    - (floored_uv.x > borders.y ? (floored_uv.x - borders.y)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.y > borders.y ? (floored_uv.y - borders.y)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.x < borders.x ? (borders.x - floored_uv.x)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.y < borders.x ? (borders.x - floored_uv.y)*(5. + 5.*dissolve) : 0.)*(dissolve);

    if (tex.a > 0.01 && burn_colour_1.a > 0.01 && !shadow && res < adjusted_dissolve + 0.8*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
        if (!shadow && res < adjusted_dissolve + 0.5*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
            tex.rgba = burn_colour_1.rgba;
        } else if (burn_colour_2.a > 0.01) {
            tex.rgba = burn_colour_2.rgba;
        }
    }

    return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, res > adjusted_dissolve ? (shadow ? tex.a*0.3: tex.a) : .0);
}

// Gaussian bump centred on 0, w = half-width
float bump(float x, float w)
{
	float k = x / w;
	return exp(-k*k);
}

// Cheap pseudo-random hash, used for the glitter grain
float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect( vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 tex = Texel( texture, texture_coords);
    vec2 uv = (((texture_coords)*(image_details)) - texture_details.xy*texture_details.ba)/texture_details.ba;
    vec2 c = uv - 0.5;

    // 1. Periodic sweep. polished.g is real time; the band crosses the card, then rests.
    float d = c.x + c.y * SWEEP_SLANT;                      // distance along the sweep axis
    float phase = mod(polished.g, SWEEP_PERIOD) / SWEEP_PERIOD;
    float t = clamp(phase / SWEEP_FRACTION, 0., 1.);
    t = t*t*(3. - 2.*t);                                    // ease in/out
    float pos = mix(-1.1, 1.1, t);                          // starts and ends off-card

    float core  = bump(d - pos,        0.035);              // bright centre line
    float halo  = bump(d - pos,        0.16);               // soft glow around it
    float trail = bump(d - pos + 0.13, 0.012);              // thin glass-like echo behind it
    float sweep = core + 0.35*halo + 0.5*trail;

    // 2. Soft hotspot that drifts with tilt / hover (polished.x)
    vec2 hot = vec2(0.5 + 0.4*sin(polished.x*3.1), 0.5 + 0.4*cos(polished.x*2.3));
    vec2 hv = uv - hot;
    float spec = exp(-dot(hv, hv) / 0.06);

    // 2b. Static glass sheen — a soft diagonal band always present, not tied to the sweep timer,
    // so the card reads as a different material even during the sweep's downtime.
    float gd = c.x + c.y * GLASS_SLANT;
    float glass = 1.0 - smoothstep(0.0, GLASS_WIDTH, abs(gd + 0.15));

    // 2c. Fine glitter grain, catches light like tiny facets in glass
    vec2 grain_uv = floor(uv * GLITTER_SCALE);
    float g = hash(grain_uv + floor(polished.g * 2.0));     // ticks over a couple times/sec
    float glitter = smoothstep(0.95, 1.0, g);               // only the brightest flecks show

    // 3. Bevel rim that catches light, brighter as the band passes
    vec2 e = min(uv, 1. - uv);
    float rim = 1. - smoothstep(0., 0.05, min(e.x, e.y));

    // 4. Output light only: cool halo, warm-white core. Alpha = how much light.
    vec3 shine_col = mix(vec3(0.72, 0.88, 1.0), vec3(1.0, 0.98, 0.93), core);
    shine_col = mix(shine_col, vec3(1.0), glitter*0.6);
    float light = clamp(SHINE_STRENGTH*sweep
                      + HOTSPOT_STRENGTH*spec
                      + rim*(RIM_BASE + RIM_SWEEP*halo)
                      + GLASS_STRENGTH*glass
                      + GLITTER_STRENGTH*glitter, 0., 1.);

    // Run the mask with the sprite's own alpha so the overlay dissolves in sync with the card,
    // then scale by the light amount.
    vec4 masked = dissolve_mask(vec4(shine_col, tex.a), texture_coords, uv);
    masked.a *= light;
    return masked;
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