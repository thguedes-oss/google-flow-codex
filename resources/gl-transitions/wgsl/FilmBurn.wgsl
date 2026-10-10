// Ported from FilmBurn.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: cbd7ffe97b9e582bb0d775f81ddf309a263746d4d48bae08777e788118cb9dac
// Original authors: Anastasia Dunbar
// License: MIT; full original notices in ../originals/FilmBurn.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  Seed: f32,
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
var<private> g_Seed: f32;
fn g_sigmoid(a_x: f32, a_a: f32) -> f32 {
var g_x: f32 = a_x;
var g_a: f32 = a_a;

var g_b: f32 = (pow((g_x * 2.0), g_a) / 2.0);
if ((g_x > 0.5)) {
g_b = (1.0 - (pow((2.0 - (g_x * 2.0)), g_a) / 2.0));
}
return g_b;
}
fn g_rand__float(a_co: f32) -> f32 {
var g_co: f32 = a_co;

return fract((sin(((g_co * 24.9898) + g_Seed)) * 43758.5453));
}
fn g_rand__vec2(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_apow(a_a: f32, a_b: f32) -> f32 {
var g_a: f32 = a_a;
var g_b: f32 = a_b;

return (pow(abs(g_a), g_b) * sign(g_b));
}
fn g_pow3(a_a: vec3<f32>, a_b: vec3<f32>) -> vec3<f32> {
var g_a: vec3<f32> = a_a;
var g_b: vec3<f32> = a_b;

return vec3<f32>(g_apow(g_a.r, g_b.r), g_apow(g_a.g, g_b.g), g_apow(g_a.b, g_b.b));
}
fn g_smooth_mix(a_a: f32, a_b: f32, a_c: f32) -> f32 {
var g_a: f32 = a_a;
var g_b: f32 = a_b;
var g_c: f32 = a_c;

return mix(g_a, g_b, g_sigmoid(g_c, 2.0));
}
fn g_random(a_co: vec2<f32>, a_shft: f32) -> f32 {
var g_co: vec2<f32> = a_co;
var g_shft: f32 = a_shft;

g_co += vec2<f32>(10.0);
return g_smooth_mix(fract((sin(dot(g_co.xy, vec2<f32>((12.9898 + (floor(g_shft) * 0.5)), (78.233 + g_Seed)))) * 43758.5453)), fract((sin(dot(g_co.xy, vec2<f32>((12.9898 + (floor((g_shft + 1.0)) * 0.5)), (78.233 + g_Seed)))) * 43758.5453)), fract(g_shft));
}
fn g_smooth_random(a_co: vec2<f32>, a_shft: f32) -> f32 {
var g_co: vec2<f32> = a_co;
var g_shft: f32 = a_shft;

return g_smooth_mix(g_smooth_mix(g_random(floor(g_co), g_shft), g_random(floor((g_co + vec2<f32>(1.0, 0.0))), g_shft), fract(g_co.x)), g_smooth_mix(g_random(floor((g_co + vec2<f32>(0.0, 1.0))), g_shft), g_random(floor((g_co + vec2<f32>(1.0, 1.0))), g_shft), fract(g_co.x)), fract(g_co.y));
}
fn g_blendedColor(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_sigmoid(g_progress, 10.0)));
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_f: vec3<f32> = vec3<f32>(0.0);
for (var g_i: f32 = 0.0; (g_i < 13.0); g_i += 1.0) {
g_f += vec3<f32>((sin(((((g_p.x * g_rand__float(g_i)) * 6.0) + (g_progress * 8.0)) + g_rand__float((g_i + 1.43)))) * sin(((((g_p.y * g_rand__float((g_i + 4.4))) * 6.0) + (g_progress * 6.0)) + g_rand__float((g_i + 2.4))))));
g_f += vec3<f32>((1.0 - clamp((length((g_p - vec2<f32>(g_smooth_random(vec2<f32>((g_progress * 1.3)), (g_i + 1.0)), g_smooth_random(vec2<f32>((g_progress * 0.5)), (g_i + 6.25))))) * mix(20.0, 70.0, g_rand__float(g_i))), 0.0, 1.0)));
}
g_f += vec3<f32>(4.0);
g_f /= vec3<f32>(11.0);
g_f = g_pow3((g_f * vec3<f32>(1.0, 0.7, 0.6)), vec3<f32>(1.0, (2.0 - sin((g_progress * 3.14159265358979323))), 1.3));
g_f *= vec3<f32>(sin((g_progress * 3.14159265358979323)));
g_p -= vec2<f32>(0.5);
g_p *= vec2<f32>((1.0 + ((g_smooth_random(vec2<f32>((g_progress * 5.0)), 6.3) * sin((g_progress * 3.14159265358979323))) * 0.05)));
g_p += vec2<f32>(0.5);
var g_blurred_image: vec4<f32> = vec4<f32>(0.0);
var g_bluramount: f32 = (sin((g_progress * 3.14159265358979323)) * 0.03);
for (var g_i: f32 = 0.0; (g_i < 50.0); g_i += 1.0) {
var g_q: vec2<f32> = (vec2<f32>(cos(degrees(((g_i / 50.0) * 360.0))), sin(degrees(((g_i / 50.0) * 360.0)))) * vec2<f32>((g_rand__vec2(vec2<f32>(g_i, (g_p.x + g_p.y))) + g_bluramount)));
var g_uv2: vec2<f32> = (g_p + (g_q * vec2<f32>(g_bluramount)));
g_blurred_image += g_blendedColor(g_uv2);
}
g_blurred_image /= vec4<f32>(50.0);
return (g_blurred_image + vec4<f32>(g_f, 0.0));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_Seed = params.Seed;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
