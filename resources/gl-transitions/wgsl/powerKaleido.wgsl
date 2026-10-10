// Ported from powerKaleido.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: f6448f3aa5446f5f9ff623ffda299b5ab573522a69c863cbb2a8e4c63f3d7291
// Original authors: Boundless
// License: MIT; full original notices in ../originals/powerKaleido.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  scale: f32,
  z: f32,
  speed: f32,
  _pad0: f32,
  _pad1: f32,
  _pad2: f32,
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
var<private> g_scale: f32;
var<private> g_z: f32;
var<private> g_speed: f32;
var<private> g_rad: f32;
var<private> g_deg: f32;
fn g_refl(a_p: vec2<f32>, a_o: vec2<f32>, a_n: vec2<f32>) -> vec2<f32> {
var g_p: vec2<f32> = a_p;
var g_o: vec2<f32> = a_o;
var g_n: vec2<f32> = a_n;

return (((vec2<f32>(2.0) * g_o) + ((vec2<f32>(2.0) * g_n) * vec2<f32>(dot((g_p - g_o), g_n)))) - g_p);
}
fn g_rot(a_p: vec2<f32>, a_o: vec2<f32>, a_a: f32) -> vec2<f32> {
var g_p: vec2<f32> = a_p;
var g_o: vec2<f32> = a_o;
var g_a: f32 = a_a;

var g_s: f32 = sin(g_a);
var g_c: f32 = cos(g_a);
return (g_o + (mat2x2<f32>(vec2<f32>(g_c, (-g_s)), vec2<f32>(g_s, g_c)) * (g_p - g_o)));
}
fn g_mainImage(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_dist: f32 = (g_scale / 10.0);
var g_uv0: vec2<f32> = g_uv;
g_uv -= vec2<f32>(0.5);
g_uv.x *= g_ratio;
g_uv *= vec2<f32>(g_z);
g_uv = g_rot(g_uv, vec2<f32>(0.0), (g_progress * g_speed));
var g_theta: f32 = ((g_progress * 6.0) + (3.14159265358979 / 0.5));
for (var g_iter: i32 = 0; (g_iter < 10); g_iter++) {
for (var g_i: f32 = 0.0; (g_i < (2.0 * 3.14159265358979)); g_i += g_deg) {
var g_ts: f32 = select(0.0, 1.0, (sign(asin(cos(g_i))) == 1.0));
if ((((g_ts == 1.0) && ((g_uv.y - (g_dist * cos(g_i))) > (tan(g_i) * (g_uv.x + (g_dist * sin(g_i)))))) || ((g_ts == 0.0) && ((g_uv.y - (g_dist * cos(g_i))) < (tan(g_i) * (g_uv.x + (g_dist * sin(g_i)))))))) {
g_uv = g_refl(vec2<f32>((g_uv.x + ((sin(g_i) * g_dist) * 2.0)), (g_uv.y - ((cos(g_i) * g_dist) * 2.0))), vec2<f32>(0.0, 0.0), vec2<f32>(cos(g_i), sin(g_i)));
}
}
}
g_uv += vec2<f32>(0.5);
g_uv = g_rot(g_uv, vec2<f32>(0.5), (g_progress * (-g_speed)));
g_uv -= vec2<f32>(0.5);
g_uv.x /= g_ratio;
g_uv += vec2<f32>(0.5);
g_uv = (vec2<f32>(2.0) * abs(((g_uv / vec2<f32>(2.0)) - floor(((g_uv / vec2<f32>(2.0)) + vec2<f32>(0.5))))));
var g_uvMix: vec2<f32> = mix(g_uv, g_uv0, vec2<f32>(((cos(((g_progress * 3.14159265358979) * 2.0)) / 2.0) + 0.5)));
var g_color: vec4<f32> = mix(getFromColor(g_uvMix), getToColor(g_uvMix), vec4<f32>(((cos(((g_progress - 1.0) * 3.14159265358979)) / 2.0) + 0.5)));
return g_color;
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_color: vec4<f32> = g_mainImage(g_uv);
return g_color;
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_scale = params.scale;
g_z = params.z;
g_speed = params.speed;
g_rad = 120.0;
g_deg = ((g_rad / 180.0) * 3.14159265358979);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
