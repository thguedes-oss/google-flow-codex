// Ported from Slides.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: cd22cf496b485f7c4b9fcefca6f18bbcc6b7e01fbb93e4c01b0620e392bd1245
// Original authors: Mark Craig
// License: MIT; full original notices in ../originals/Slides.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  p_type: f32,
  In: f32,
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
var<private> g_type: i32;
var<private> g_In: bool;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_uv0: vec2<f32> = g_uv;
var g_rad: f32 = select((1.0 - g_progress), g_progress, g_In);
var g_xc1: f32;
var g_yc1: f32;
if ((g_type == 0)) {
g_xc1 = (0.5 - (g_rad / 2.0));
g_yc1 = 0.0;
} else {
if ((g_type == 1)) {
g_xc1 = (1.0 - g_rad);
g_yc1 = (0.5 - (g_rad / 2.0));
} else {
if ((g_type == 2)) {
g_xc1 = (0.5 - (g_rad / 2.0));
g_yc1 = (1.0 - g_rad);
} else {
if ((g_type == 3)) {
g_xc1 = 0.0;
g_yc1 = (0.5 - (g_rad / 2.0));
} else {
if ((g_type == 4)) {
g_xc1 = (1.0 - g_rad);
g_yc1 = 0.0;
} else {
if ((g_type == 5)) {
g_xc1 = (1.0 - g_rad);
g_yc1 = (1.0 - g_rad);
} else {
if ((g_type == 6)) {
g_xc1 = 0.0;
g_yc1 = (1.0 - g_rad);
} else {
if ((g_type == 7)) {
g_xc1 = 0.0;
g_yc1 = 0.0;
} else {
if ((g_type == 8)) {
g_xc1 = (0.5 - (g_rad / 2.0));
g_yc1 = (0.5 - (g_rad / 2.0));
}
}
}
}
}
}
}
}
}
g_uv.y = (1.0 - g_uv.y);
var g_uv2: vec2<f32>;
if (((((g_uv.x >= g_xc1) && (g_uv.x <= (g_xc1 + g_rad))) && (g_uv.y >= g_yc1)) && (g_uv.y <= (g_yc1 + g_rad)))) {
g_uv2 = vec2<f32>(((g_uv.x - g_xc1) / g_rad), (1.0 - ((g_uv.y - g_yc1) / g_rad)));
return select(getFromColor(g_uv2), getToColor(g_uv2), g_In);
}
return select(getToColor(g_uv0), getFromColor(g_uv0), g_In);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_type = i32(params.p_type);
g_In = (params.In != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
