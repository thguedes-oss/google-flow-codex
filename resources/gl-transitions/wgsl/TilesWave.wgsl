// Ported from TilesWave.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 38516173c9f2ebf3ffd4d7fd3f57afd8fa7d679effde2f4e363eef5b03bb4f9a
// Original authors: numb3r23
// License: MIT; full original notices in ../originals/TilesWave.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  tileCount_x: f32,
  tileCount_y: f32,
  flipX: f32,
  flipY: f32,
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
var<private> g_tileCount: vec2<i32>;
var<private> g_flipX: bool;
var<private> g_flipY: bool;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_tileSize: vec2<f32> = (vec2<f32>(1.0) / vec2<f32>(vec2<f32>(g_tileCount)));
var g_posInTile: vec2<f32> = fract((g_uv * vec2<f32>(vec2<f32>(g_tileCount))));
var g_tileNum: vec2<f32> = floor((g_uv * vec2<f32>(vec2<f32>(g_tileCount))));
var g_countTiles: f32 = f32(f32((g_tileCount.x * g_tileCount.y)));
var g_offset: f32 = ((g_tileNum.y + (g_tileNum.x * f32(f32(g_tileCount.y)))) / g_countTiles);
var g_timeOffset: f32 = clamp(((g_progress - g_offset) * g_countTiles), 0.0, 0.5);
var g_sinTime: f32 = (1.0 - abs(cos((fract(g_timeOffset) * 3.1415926))));
var g_texC: vec2<f32> = g_posInTile;
if ((g_sinTime <= 0.5)) {
if (g_flipX) {
if (((g_texC.x < g_sinTime) || (g_texC.x > (1.0 - g_sinTime)))) {
return getFromColor(g_uv);
}
g_texC.x = select(((((g_texC.x - 0.5) * 0.5) / (0.5 - g_sinTime)) + 0.5), (((g_texC.x - g_sinTime) * 0.5) / (0.5 - g_sinTime)), (g_texC.x < 0.5));
}
if (g_flipY) {
if (((g_texC.y < g_sinTime) || (g_texC.y > (1.0 - g_sinTime)))) {
return getFromColor(g_uv);
}
g_texC.y = select(((((g_texC.y - 0.5) * 0.5) / (0.5 - g_sinTime)) + 0.5), (((g_texC.y - g_sinTime) * 0.5) / (0.5 - g_sinTime)), (g_texC.y < 0.5));
}
var g_globalUV: vec2<f32> = ((g_tileNum * g_tileSize) + (g_texC * g_tileSize));
return getFromColor(g_globalUV);
} else {
if (g_flipX) {
if (((g_texC.x > g_sinTime) || (g_texC.x < (1.0 - g_sinTime)))) {
return getToColor(g_uv);
}
g_texC.x = select(((((g_texC.x - 0.5) * 0.5) / (0.5 - g_sinTime)) + 0.5), (((g_texC.x - g_sinTime) * 0.5) / (0.5 - g_sinTime)), (g_texC.x < 0.5));
g_texC.x = (1.0 - g_texC.x);
}
if (g_flipY) {
if (((g_texC.y > g_sinTime) || (g_texC.y < (1.0 - g_sinTime)))) {
return getToColor(g_uv);
}
g_texC.y = select(((((g_texC.y - 0.5) * 0.5) / (0.5 - g_sinTime)) + 0.5), (((g_texC.y - g_sinTime) * 0.5) / (0.5 - g_sinTime)), (g_texC.y < 0.5));
g_texC.y = (1.0 - g_texC.y);
}
var g_globalUV: vec2<f32> = ((g_tileNum * g_tileSize) + (g_texC * g_tileSize));
return getToColor(g_globalUV);
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_tileCount = vec2<i32>(i32(params.tileCount_x), i32(params.tileCount_y));
g_flipX = (params.flipX != f32(0));
g_flipY = (params.flipY != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
