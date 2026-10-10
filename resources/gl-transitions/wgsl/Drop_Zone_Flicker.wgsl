// Ported from Drop_Zone_Flicker.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 6a9be7ee75c747899bc86366bd99b4842af08ea39311811ca3ef9610b644b854
// Original authors: bread
// License: MIT; full original notices in ../originals/Drop_Zone_Flicker.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  frameRate: f32,
  rgbOffset: f32,
  blockAmount: f32,
  ghostAmount: f32,
  redCyan: f32,
  scanline: f32,
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
var<private> g_frameRate: f32;
var<private> g_rgbOffset: f32;
var<private> g_blockAmount: f32;
var<private> g_ghostAmount: f32;
var<private> g_redCyan: f32;
var<private> g_scanline: f32;
fn g_sat(a_x: f32) -> f32 {
var g_x: f32 = a_x;

return clamp(g_x, 0.0, 1.0);
}
fn g_hash12(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

g_p = fract((g_p * vec2<f32>(443.8975, 397.2973)));
g_p += vec2<f32>(dot(g_p, (g_p.yx + vec2<f32>(19.19))));
return fract((g_p.x * g_p.y));
}
fn g_safeUv(a_uv: vec2<f32>) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;

return clamp(g_uv, vec2<f32>(0.001), vec2<f32>(0.999));
}
fn g_frameReveal(a_f: f32) -> f32 {
var g_f: f32 = a_f;

if ((g_f < 0.5)) {
return 0.00;
}
if ((g_f < 1.5)) {
return 0.28;
}
if ((g_f < 2.5)) {
return 0.43;
}
if ((g_f < 3.5)) {
return 0.46;
}
if ((g_f < 4.5)) {
return 0.38;
}
if ((g_f < 5.5)) {
return 0.48;
}
if ((g_f < 6.5)) {
return 0.26;
}
if ((g_f < 7.5)) {
return 0.10;
}
if ((g_f < 8.5)) {
return 0.00;
}
if ((g_f < 9.5)) {
return 0.00;
}
if ((g_f < 10.5)) {
return 0.30;
}
if ((g_f < 11.5)) {
return 0.58;
}
if ((g_f < 12.5)) {
return 1.00;
}
if ((g_f < 13.5)) {
return 0.70;
}
if ((g_f < 14.5)) {
return 0.42;
}
if ((g_f < 15.5)) {
return 0.55;
}
if ((g_f < 16.5)) {
return 0.72;
}
if ((g_f < 17.5)) {
return 0.88;
}
if ((g_f < 18.5)) {
return 0.34;
}
if ((g_f < 19.5)) {
return 0.48;
}
if ((g_f < 20.5)) {
return 0.56;
}
if ((g_f < 21.5)) {
return 0.76;
}
if ((g_f < 22.5)) {
return 0.93;
}
return 1.00;
}
fn g_frameGlitch(a_f: f32) -> f32 {
var g_f: f32 = a_f;

if ((g_f < 0.5)) {
return 0.00;
}
if ((g_f < 6.5)) {
return 0.92;
}
if ((g_f < 10.5)) {
return 0.38;
}
if ((g_f < 11.5)) {
return 0.78;
}
if ((g_f < 12.5)) {
return 0.12;
}
if ((g_f < 17.5)) {
return 0.74;
}
if ((g_f < 22.5)) {
return 0.88;
}
if ((g_f < 23.5)) {
return 0.28;
}
return 0.00;
}
fn g_chromaFrom(a_uv: vec2<f32>, a_amt: f32) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_amt: f32 = a_amt;

var g_o: vec2<f32> = vec2<f32>(g_amt, 0.0);
return vec4<f32>(getFromColor(g_safeUv((g_uv + g_o))).r, getFromColor(g_safeUv(g_uv)).g, getFromColor(g_safeUv((g_uv - g_o))).b, 1.0);
}
fn g_chromaTo(a_uv: vec2<f32>, a_amt: f32) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_amt: f32 = a_amt;

var g_o: vec2<f32> = vec2<f32>(g_amt, 0.0);
return vec4<f32>(getToColor(g_safeUv((g_uv - g_o))).r, getToColor(g_safeUv(g_uv)).g, getToColor(g_safeUv((g_uv + g_o))).b, 1.0);
}
fn g_blockMask(a_uv: vec2<f32>, a_f: f32) -> f32 {
var g_uv: vec2<f32> = a_uv;
var g_f: f32 = a_f;

var g_big: vec2<f32> = floor((g_uv * vec2<f32>(4.0, 2.0)));
var g_small: vec2<f32> = floor((g_uv * vec2<f32>(8.0, 4.0)));
var g_wide: f32 = step(0.48, g_hash12(vec2<f32>(g_big.x, (g_f * 1.37))));
var g_chunks: f32 = step(0.56, g_hash12((g_small + vec2<f32>((g_f * 2.11), (g_f * 0.73)))));
var g_verticalCut: f32 = smoothstep((-0.035), 0.035, (g_uv.x - mix(0.18, 0.78, g_hash12(vec2<f32>(g_f, 4.7)))));
return g_sat(((mix(g_wide, g_chunks, 0.38) * 0.72) + (g_verticalCut * 0.28)));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress <= 0.0)) {
return getFromColor(g_uv);
}
if ((g_progress >= 1.0)) {
return getToColor(g_uv);
}
var g_f: f32 = floor((g_progress * g_frameRate));
var g_reveal: f32 = g_frameReveal(g_f);
var g_glitch: f32 = g_frameGlitch(g_f);
var g_rnd: f32 = g_hash12(vec2<f32>(g_f, 9.13));
var g_jitter: vec2<f32> = (vec2<f32>(((g_rnd - 0.5) * 0.042), ((g_hash12(vec2<f32>(g_f, 2.71)) - 0.5) * 0.010)) * vec2<f32>(g_glitch));
var g_fromUv: vec2<f32> = g_safeUv((g_uv + g_jitter));
var g_toUv: vec2<f32> = g_safeUv((g_uv - (g_jitter * vec2<f32>(0.55))));
var g_block: f32 = g_blockMask(g_uv, g_f);
var g_localReveal: f32 = g_sat(((g_reveal + (((g_block - 0.5) * g_blockAmount) * g_glitch)) + (((g_hash12(vec2<f32>(g_f, floor((g_uv.y * 9.0)))) - 0.5) * 0.18) * g_glitch)));
g_localReveal = smoothstep(0.22, 0.78, g_localReveal);
var g_oldClip: vec4<f32> = g_chromaFrom(g_fromUv, (g_rgbOffset * g_glitch));
var g_newClip: vec4<f32> = g_chromaTo(g_toUv, (g_rgbOffset * g_glitch));
var g_color: vec4<f32> = mix(g_oldClip, g_newClip, vec4<f32>(g_localReveal));
var g_leftWash: f32 = ((1.0 - smoothstep(0.10, 0.78, g_uv.x)) * g_glitch);
var g_cyanWash: f32 = ((smoothstep(0.08, 0.62, g_uv.x) * (1.0 - smoothstep(0.86, 1.0, g_uv.x))) * g_glitch);
var g_redGhost: vec3<f32> = (g_oldClip.rgb * vec3<f32>(1.34, 0.42, 0.38));
var g_cyanGhost: vec3<f32> = (g_newClip.rgb * vec3<f32>(0.48, 1.12, 1.24));
g_color = vec4<f32>((mix(g_color.rgb, g_redGhost, vec3<f32>(((g_leftWash * g_redCyan) * 0.42)))).x, (mix(g_color.rgb, g_redGhost, vec3<f32>(((g_leftWash * g_redCyan) * 0.42)))).y, (mix(g_color.rgb, g_redGhost, vec3<f32>(((g_leftWash * g_redCyan) * 0.42)))).z, g_color.w);
g_color = vec4<f32>((mix(g_color.rgb, g_cyanGhost, vec3<f32>(((g_cyanWash * g_redCyan) * 0.30)))).x, (mix(g_color.rgb, g_cyanGhost, vec3<f32>(((g_cyanWash * g_redCyan) * 0.30)))).y, (mix(g_color.rgb, g_cyanGhost, vec3<f32>(((g_cyanWash * g_redCyan) * 0.30)))).z, g_color.w);
var g_oldReturn: f32 = (g_glitch * (1.0 - smoothstep(0.94, 1.0, g_reveal)));
g_oldReturn *= (0.18 + (0.52 * (1.0 - (abs((g_localReveal - 0.5)) * 2.0))));
g_color = vec4<f32>((mix(g_color.rgb, g_oldClip.rgb, vec3<f32>((g_oldReturn * g_ghostAmount)))).x, (mix(g_color.rgb, g_oldClip.rgb, vec3<f32>((g_oldReturn * g_ghostAmount)))).y, (mix(g_color.rgb, g_oldClip.rgb, vec3<f32>((g_oldReturn * g_ghostAmount)))).z, g_color.w);
var g_lines: f32 = sin(((g_uv.y + (g_f * 0.017)) * 1080.0));
g_color = vec4<f32>((g_color.x + (vec3<f32>(((g_lines * g_scanline) * g_glitch))).x), (g_color.y + (vec3<f32>(((g_lines * g_scanline) * g_glitch))).y), (g_color.z + (vec3<f32>(((g_lines * g_scanline) * g_glitch))).z), g_color.w);
var g_exposurePulse: f32 = (((g_hash12(vec2<f32>(g_f, 12.4)) - 0.35) * 0.10) * g_glitch);
g_color = vec4<f32>((g_color.x + (vec3<f32>(g_exposurePulse)).x), (g_color.y + (vec3<f32>(g_exposurePulse)).y), (g_color.z + (vec3<f32>(g_exposurePulse)).z), g_color.w);
return vec4<f32>(g_sat(g_color.r), g_sat(g_color.g), g_sat(g_color.b), 1.0);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_frameRate = params.frameRate;
g_rgbOffset = params.rgbOffset;
g_blockAmount = params.blockAmount;
g_ghostAmount = params.ghostAmount;
g_redCyan = params.redCyan;
g_scanline = params.scanline;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
