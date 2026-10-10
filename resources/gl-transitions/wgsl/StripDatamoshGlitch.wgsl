// Ported from StripDatamoshGlitch.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 61f819c2ab5263828da3a13a3bfc6142b80485064f7cd23ec4733b2b4160ad81
// Original authors: bread
// License: MIT; full original notices in ../originals/StripDatamoshGlitch.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  strength: f32,
  horizontalBars: f32,
  verticalSlits: f32,
  tear: f32,
  chroma: f32,
  residue: f32,
  noiseAmount: f32,
  scanAmount: f32,
  flashAmount: f32,
  _pad0: f32,
};

struct VertexInput {
 @location(0) position: vec2<f32>,
 @location(1) tex_coords: vec2<f32>,
 @location(2) color: vec4<f32>,
};
struct VertexOutput {
 @builtin(position) clip_position: vec4<f32>,
 @location(0) tex_coords: vec2<f32>,
};
@vertex fn vs_main(input: VertexInput) -> VertexOutput {
 var out: VertexOutput;
 out.clip_position=vec4<f32>(input.position,0.0,1.0);
 out.tex_coords=input.tex_coords;
 return out;
}
@group(0) @binding(0) var t_from: texture_2d<f32>;
@group(0) @binding(1) var t_to: texture_2d<f32>;
@group(0) @binding(2) var s_sampler: sampler;
@group(0) @binding(3) var<uniform> params: Params;
// GL coordinates are bottom-up. Both boundary conversions preserve native orientation.
fn getFromColor(uv: vec2<f32>) -> vec4<f32> {
 return textureSampleLevel(t_from,s_sampler,vec2<f32>(uv.x,1.0-uv.y),0.0);
}
fn getToColor(uv: vec2<f32>) -> vec4<f32> {
 return textureSampleLevel(t_to,s_sampler,vec2<f32>(uv.x,1.0-uv.y),0.0);
}

var<private> g_progress: f32;
var<private> g_ratio: f32;
var<private> g_strength: f32;
var<private> g_horizontalBars: f32;
var<private> g_verticalSlits: f32;
var<private> g_tear: f32;
var<private> g_chroma: f32;
var<private> g_residue: f32;
var<private> g_noiseAmount: f32;
var<private> g_scanAmount: f32;
var<private> g_flashAmount: f32;
var<private> g_PI: f32;
fn g_hash__float(a_n: f32) -> f32 {
var g_n: f32 = a_n;

return fract((sin(g_n) * 43758.5453123));
}
fn g_hash__vec2(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

return fract((sin(dot(g_p, vec2<f32>(127.1, 311.7))) * 43758.5453123));
}
fn g_sat(a_v: f32) -> f32 {
var g_v: f32 = a_v;

return clamp(g_v, 0.0, 1.0);
}
fn g_burst() -> f32 {

return (pow(max(0.0, sin((g_progress * g_PI))), 0.42) * g_strength);
}
fn g_safeUv(a_uv: vec2<f32>) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;

return clamp(g_uv, vec2<f32>(0.0), vec2<f32>(1.0));
}
fn g_stripeY(a_uv: vec2<f32>, a_density: f32, a_seed: f32, a_minWidth: f32, a_maxWidth: f32) -> f32 {
var g_uv: vec2<f32> = a_uv;
var g_density: f32 = a_density;
var g_seed: f32 = a_seed;
var g_minWidth: f32 = a_minWidth;
var g_maxWidth: f32 = a_maxWidth;

var g_y: f32 = ((g_uv.y * g_density) + (g_seed * 0.137));
var g_id: f32 = floor(g_y);
var g_f: f32 = fract(g_y);
var g_c: f32 = g_hash__vec2(vec2<f32>(g_id, g_seed));
var g_w: f32 = mix(g_minWidth, g_maxWidth, g_hash__vec2(vec2<f32>((g_id + 9.17), (g_seed + 2.31))));
return (1.0 - smoothstep(g_w, (g_w + 0.018), abs((g_f - g_c))));
}
fn g_stripeX(a_uv: vec2<f32>, a_density: f32, a_seed: f32, a_minWidth: f32, a_maxWidth: f32) -> f32 {
var g_uv: vec2<f32> = a_uv;
var g_density: f32 = a_density;
var g_seed: f32 = a_seed;
var g_minWidth: f32 = a_minWidth;
var g_maxWidth: f32 = a_maxWidth;

var g_x: f32 = ((g_uv.x * g_density) + (g_seed * 0.091));
var g_id: f32 = floor(g_x);
var g_f: f32 = fract(g_x);
var g_c: f32 = g_hash__vec2(vec2<f32>(g_id, (g_seed + 41.0)));
var g_w: f32 = mix(g_minWidth, g_maxWidth, g_hash__vec2(vec2<f32>((g_id + 4.7), (g_seed + 8.9))));
return (1.0 - smoothstep(g_w, (g_w + 0.012), abs((g_f - g_c))));
}
fn g_brokenGate(a_uv: vec2<f32>, a_row: f32, a_rnd: f32, a_frame: f32) -> f32 {
var g_uv: vec2<f32> = a_uv;
var g_row: f32 = a_row;
var g_rnd: f32 = a_rnd;
var g_frame: f32 = a_frame;

var g_segs: f32 = mix(1.0, 9.0, g_hash__vec2(vec2<f32>(g_row, (g_frame + 44.0))));
var g_seg: f32 = floor((g_uv.x * g_segs));
return step(0.16, g_hash__vec2(vec2<f32>(g_seg, ((g_row + (g_frame * 3.0)) + g_rnd))));
}
fn g_horizontalMask(a_uv: vec2<f32>, a_frame: f32) -> f32 {
var g_uv: vec2<f32> = a_uv;
var g_frame: f32 = a_frame;

var g_r1: f32 = floor((((g_uv.y + (g_hash__float(g_frame) * 0.031)) * g_horizontalBars) * 0.38));
var g_r2: f32 = floor(((g_uv.y + (g_hash__float((g_frame + 2.0)) * 0.013)) * g_horizontalBars));
var g_r3: f32 = floor((((g_uv.y + (g_hash__float((g_frame + 7.0)) * 0.006)) * g_horizontalBars) * 3.4));
var g_thick: f32 = g_stripeY(g_uv, (g_horizontalBars * 0.38), (g_frame + 1.0), 0.035, 0.22);
var g_mid: f32 = g_stripeY(g_uv, g_horizontalBars, (g_frame + 4.0), 0.014, 0.11);
var g_hair: f32 = g_stripeY(g_uv, (g_horizontalBars * 3.4), (g_frame + 9.0), 0.004, 0.035);
g_thick *= step(0.42, g_hash__vec2(vec2<f32>(g_r1, (g_frame + 10.0))));
g_mid *= step(0.48, g_hash__vec2(vec2<f32>(g_r2, (g_frame + 20.0))));
g_hair *= step(0.62, g_hash__vec2(vec2<f32>(g_r3, (g_frame + 30.0))));
g_thick *= g_brokenGate(g_uv, g_r1, g_hash__vec2(vec2<f32>(g_r1, g_frame)), g_frame);
g_mid *= g_brokenGate(g_uv, g_r2, g_hash__vec2(vec2<f32>(g_r2, g_frame)), (g_frame + 3.0));
return g_sat(max(g_thick, max(g_mid, g_hair)));
}
fn g_verticalMask(a_uv: vec2<f32>, a_frame: f32) -> f32 {
var g_uv: vec2<f32> = a_uv;
var g_frame: f32 = a_frame;

var g_col: f32 = floor(((g_uv.x + (g_hash__float((g_frame + 12.0)) * 0.017)) * g_verticalSlits));
var g_slit: f32 = g_stripeX(g_uv, g_verticalSlits, (g_frame + 13.0), 0.01, 0.075);
g_slit *= step(0.66, g_hash__vec2(vec2<f32>(g_col, (g_frame + 19.0))));
return g_sat(g_slit);
}
fn g_chromaFrom(a_uv: vec2<f32>, a_s: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_s: vec2<f32> = a_s;

g_uv = g_safeUv(g_uv);
return vec4<f32>(getFromColor(g_safeUv((g_uv + g_s))).r, getFromColor(g_uv).g, getFromColor(g_safeUv((g_uv - g_s))).b, 1.0);
}
fn g_chromaTo(a_uv: vec2<f32>, a_s: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_s: vec2<f32> = a_s;

g_uv = g_safeUv(g_uv);
return vec4<f32>(getToColor(g_safeUv((g_uv - g_s))).r, getToColor(g_uv).g, getToColor(g_safeUv((g_uv + g_s))).b, 1.0);
}
fn g_distortUv(a_uv: vec2<f32>, a_dir: f32, a_b: f32, a_h: f32, a_v: f32, a_frame: f32) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;
var g_dir: f32 = a_dir;
var g_b: f32 = a_b;
var g_h: f32 = a_h;
var g_v: f32 = a_v;
var g_frame: f32 = a_frame;

var g_row: f32 = floor((g_uv.y * g_horizontalBars));
var g_col: f32 = floor((g_uv.x * g_verticalSlits));
var g_rowRnd: f32 = g_hash__vec2(vec2<f32>(g_row, g_frame));
var g_colRnd: f32 = g_hash__vec2(vec2<f32>(g_col, (g_frame + 27.0)));
var g_xTear: f32 = (((((g_rowRnd - 0.5) * 2.0) * g_tear) * g_b) * g_h);
g_xTear += ((sin(((g_uv.y * 120.0) + (g_progress * 95.0))) * 0.006) * g_b);
var g_yDrag: f32 = ((((g_colRnd - 0.5) * 0.13) * g_b) * g_v);
var g_micro: f32 = ((((g_hash__vec2(vec2<f32>(g_row, (g_col + g_frame))) - 0.5) * 0.018) * g_b) * max(g_h, g_v));
return (g_uv + vec2<f32>(((g_xTear * g_dir) + g_micro), g_yDrag));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress <= 0.0)) {
return getFromColor(g_uv);
}
if ((g_progress >= 1.0)) {
return getToColor(g_uv);
}
var g_b: f32 = g_burst();
var g_frame: f32 = floor((g_progress * 30.0));
var g_h: f32 = g_horizontalMask(g_uv, g_frame);
var g_v: f32 = g_verticalMask(g_uv, g_frame);
var g_glitch: f32 = g_sat(max(g_h, (g_v * 0.75)));
var g_row: f32 = floor((g_uv.y * g_horizontalBars));
var g_rowRnd: f32 = g_hash__vec2(vec2<f32>(g_row, (g_frame + 5.0)));
var g_bandDelay: f32 = (((g_rowRnd - 0.5) * 0.30) * g_h);
var g_reveal: f32 = smoothstep(0.18, 0.84, (g_progress + g_bandDelay));
var g_split: vec2<f32> = vec2<f32>(((g_chroma * g_b) * (1.0 + (1.7 * g_glitch))), (((g_chroma * 0.22) * g_b) * g_v));
var g_fromUv: vec2<f32> = g_distortUv(g_uv, 1.0, g_b, g_h, g_v, g_frame);
var g_toUv: vec2<f32> = g_distortUv(g_uv, (-1.0), g_b, g_h, g_v, g_frame);
var g_color: vec4<f32> = mix(g_chromaFrom(g_fromUv, g_split), g_chromaTo(g_toUv, g_split), vec4<f32>(g_reveal));
var g_smearUv: vec2<f32> = g_uv;
g_smearUv.x += ((((g_rowRnd - 0.5) * 0.46) * g_b) * g_h);
g_smearUv.y += ((((g_hash__vec2(vec2<f32>(g_row, (g_frame + 31.0))) - 0.5) * 0.045) * g_b) * g_h);
var g_sliceReveal: f32 = smoothstep(0.28, 0.78, (g_progress + ((g_rowRnd - 0.5) * 0.22)));
var g_sliceColor: vec4<f32> = mix(g_chromaFrom(g_smearUv, (g_split * vec2<f32>(1.65))), g_chromaTo((g_smearUv - vec2<f32>((((g_rowRnd - 0.5) * 0.18) * g_b), 0.0)), (g_split * vec2<f32>(1.65))), vec4<f32>(g_sliceReveal));
g_color = mix(g_color, g_sliceColor, vec4<f32>(((g_h * g_b) * g_residue)));
var g_hairLine: f32 = g_stripeY(g_uv, 190.0, (g_frame + 55.0), 0.002, 0.012);
g_hairLine *= step(0.70, g_hash__vec2(vec2<f32>(floor((g_uv.y * 190.0)), (g_frame + 56.0))));
g_color = vec4<f32>((g_color.x + ((((vec3<f32>(0.72, 0.90, 1.0) * vec3<f32>(g_hairLine)) * vec3<f32>(g_b)) * vec3<f32>(0.28))).x), (g_color.y + ((((vec3<f32>(0.72, 0.90, 1.0) * vec3<f32>(g_hairLine)) * vec3<f32>(g_b)) * vec3<f32>(0.28))).y), (g_color.z + ((((vec3<f32>(0.72, 0.90, 1.0) * vec3<f32>(g_hairLine)) * vec3<f32>(g_b)) * vec3<f32>(0.28))).z), g_color.w);
var g_scan: f32 = (0.5 + (0.5 * sin(((g_uv.y * 980.0) + (g_progress * 130.0)))));
g_color = vec4<f32>((g_color.x * (vec3<f32>((1.0 - ((g_scanAmount * g_b) * g_scan)))).x), (g_color.y * (vec3<f32>((1.0 - ((g_scanAmount * g_b) * g_scan)))).y), (g_color.z * (vec3<f32>((1.0 - ((g_scanAmount * g_b) * g_scan)))).z), g_color.w);
var g_nCell: vec2<f32> = floor((g_uv * vec2<f32>((360.0 * g_ratio), 210.0)));
var g_n: f32 = g_hash__vec2((g_nCell + vec2<f32>((g_frame * 7.0), (g_frame * 13.0))));
g_color = vec4<f32>((g_color.x + (vec3<f32>(((((g_n - 0.5) * g_noiseAmount) * g_b) * (0.55 + g_glitch)))).x), (g_color.y + (vec3<f32>(((((g_n - 0.5) * g_noiseAmount) * g_b) * (0.55 + g_glitch)))).y), (g_color.z + (vec3<f32>(((((g_n - 0.5) * g_noiseAmount) * g_b) * (0.55 + g_glitch)))).z), g_color.w);
var g_luma: f32 = dot(g_color.rgb, vec3<f32>(0.299, 0.587, 0.114));
g_color = vec4<f32>((mix(g_color.rgb, vec3<f32>(g_luma), vec3<f32>(((0.18 * g_b) * g_glitch)))).x, (mix(g_color.rgb, vec3<f32>(g_luma), vec3<f32>(((0.18 * g_b) * g_glitch)))).y, (mix(g_color.rgb, vec3<f32>(g_luma), vec3<f32>(((0.18 * g_b) * g_glitch)))).z, g_color.w);
var g_strobe: f32 = (step(0.78, g_hash__vec2(vec2<f32>(g_frame, 3.14))) * pow(g_b, 1.65));
g_color = vec4<f32>((g_color.x + (vec3<f32>((g_strobe * g_flashAmount))).x), (g_color.y + (vec3<f32>((g_strobe * g_flashAmount))).y), (g_color.z + (vec3<f32>((g_strobe * g_flashAmount))).z), g_color.w);
return vec4<f32>(clamp(g_color.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), 1.0);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_strength = params.strength;
g_horizontalBars = params.horizontalBars;
g_verticalSlits = params.verticalSlits;
g_tear = params.tear;
g_chroma = params.chroma;
g_residue = params.residue;
g_noiseAmount = params.noiseAmount;
g_scanAmount = params.scanAmount;
g_flashAmount = params.flashAmount;
g_PI = 3.141592653589793;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
