// Ported from GlitchDisplace.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 4c168036dc866b057e01aa8443901aa58b689ed65421a0154439822ce0502e87
// Original authors: Matt DesLauriers
// License: MIT; full original notices in ../originals/GlitchDisplace.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  _pad0: f32,
  _pad1: f32,
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
fn g_random(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

var g_a: f32 = 12.9898;
var g_b: f32 = 78.233;
var g_c: f32 = 43758.5453;
var g_dt: f32 = dot(g_co.xy, vec2<f32>(g_a, g_b));
var g_sn: f32 = (g_dt - 3.14 * floor(g_dt / 3.14));
return fract((sin(g_sn) * g_c));
}
fn g_voronoi(a_x: vec2<f32>) -> f32 {
var g_x: vec2<f32> = a_x;

var g_p: vec2<f32> = floor(g_x);
var g_f: vec2<f32> = fract(g_x);
var g_res: f32 = 8.0;
for (var g_j: f32 = (-1.0); (g_j <= 1.0); g_j += 1.0) {
for (var g_i: f32 = (-1.0); (g_i <= 1.0); g_i += 1.0) {
var g_b: vec2<f32> = vec2<f32>(g_i, g_j);
var g_r: vec2<f32> = ((g_b - g_f) + vec2<f32>(g_random((g_p + g_b))));
var g_d: f32 = dot(g_r, g_r);
g_res = min(g_res, g_d);
}
}
return sqrt(g_res);
}
fn g_displace(a_tex: vec4<f32>, a_texCoord: vec2<f32>, a_dotDepth: f32, a_textureDepth: f32, a_strength: f32) -> vec2<f32> {
var g_tex: vec4<f32> = a_tex;
var g_texCoord: vec2<f32> = a_texCoord;
var g_dotDepth: f32 = a_dotDepth;
var g_textureDepth: f32 = a_textureDepth;
var g_strength: f32 = a_strength;

var g_b: f32 = g_voronoi(((vec2<f32>(0.003) * g_texCoord) + vec2<f32>(2.0)));
var g_g: f32 = g_voronoi((vec2<f32>(0.2) * g_texCoord));
var g_r: f32 = g_voronoi((g_texCoord - vec2<f32>(1.0)));
var g_dt: vec4<f32> = (g_tex * vec4<f32>(1.0));
var g_dis: vec4<f32> = (((g_dt * vec4<f32>(g_dotDepth)) + vec4<f32>(1.0)) - (g_tex * vec4<f32>(g_textureDepth)));
g_dis.x = ((g_dis.x - 1.0) + (g_textureDepth * g_dotDepth));
g_dis.y = ((g_dis.y - 1.0) + (g_textureDepth * g_dotDepth));
g_dis.x *= g_strength;
g_dis.y *= g_strength;
var g_res_uv: vec2<f32> = g_texCoord;
g_res_uv.x = ((g_res_uv.x + g_dis.x) - 0.0);
g_res_uv.y = (g_res_uv.y + g_dis.y);
return g_res_uv;
}
fn g_ease1(a_t: f32) -> f32 {
var g_t: f32 = a_t;

return select(select((((-0.5) * pow(2.0, (10.0 - (g_t * 20.0)))) + 1.0), (0.5 * pow(2.0, ((20.0 * g_t) - 10.0))), (g_t < 0.5)), g_t, ((g_t == 0.0) || (g_t == 1.0)));
}
fn g_ease2(a_t: f32) -> f32 {
var g_t: f32 = a_t;

return select((1.0 - pow(2.0, ((-10.0) * g_t))), g_t, (g_t == 1.0));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_color1: vec4<f32> = getFromColor(g_p);
var g_color2: vec4<f32> = getToColor(g_p);
var g_disp: vec2<f32> = g_displace(g_color1, g_p, 0.33, 0.7, (1.0 - g_ease1(g_progress)));
var g_disp2: vec2<f32> = g_displace(g_color2, g_p, 0.33, 0.5, g_ease2(g_progress));
var g_dColor1: vec4<f32> = getToColor(g_disp);
var g_dColor2: vec4<f32> = getFromColor(g_disp2);
var g_val: f32 = g_ease1(g_progress);
var g_gray: vec3<f32> = vec3<f32>(dot(min(g_dColor2, g_dColor1).rgb, vec3<f32>(0.299, 0.587, 0.114)));
g_dColor2 = vec4<f32>(g_gray, 1.0);
g_dColor2 *= vec4<f32>(2.0);
g_color1 = mix(g_color1, g_dColor2, vec4<f32>(smoothstep(0.0, 0.5, g_progress)));
g_color2 = mix(g_color2, g_dColor1, vec4<f32>(smoothstep(1.0, 0.5, g_progress)));
return mix(g_color1, g_color2, vec4<f32>(g_val));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
