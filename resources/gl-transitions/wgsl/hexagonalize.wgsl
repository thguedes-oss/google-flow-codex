// Ported from hexagonalize.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: abcac2efc147d397875a233ad010d72b03986237f0955ae2b18a214987d75c08
// Original authors: Fernando Kuteken
// License: MIT; full original notices in ../originals/hexagonalize.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  steps: f32,
  horizontalHexagons: f32,
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

struct g_Hexagon {
g_q: f32,
g_r: f32,
g_s: f32,
};
var<private> g_progress: f32;
var<private> g_ratio: f32;
var<private> g_steps: i32;
var<private> g_horizontalHexagons: f32;
fn g_createHexagon(a_q: f32, a_r: f32) -> g_Hexagon {
var g_q: f32 = a_q;
var g_r: f32 = a_r;

var g_hex: g_Hexagon;
g_hex.g_q = g_q;
g_hex.g_r = g_r;
g_hex.g_s = ((-g_q) - g_r);
return g_hex;
}
fn g_roundHexagon(a_hex: g_Hexagon) -> g_Hexagon {
var g_hex: g_Hexagon = a_hex;

var g_q: f32 = floor((g_hex.g_q + 0.5));
var g_r: f32 = floor((g_hex.g_r + 0.5));
var g_s: f32 = floor((g_hex.g_s + 0.5));
var g_deltaQ: f32 = abs((g_q - g_hex.g_q));
var g_deltaR: f32 = abs((g_r - g_hex.g_r));
var g_deltaS: f32 = abs((g_s - g_hex.g_s));
if (((g_deltaQ > g_deltaR) && (g_deltaQ > g_deltaS))) {
g_q = ((-g_r) - g_s);
} else {
if ((g_deltaR > g_deltaS)) {
g_r = ((-g_q) - g_s);
} else {
g_s = ((-g_q) - g_r);
}
}
return g_createHexagon(g_q, g_r);
}
fn g_hexagonFromPoint(a_point: vec2<f32>, a_size: f32) -> g_Hexagon {
var g_point: vec2<f32> = a_point;
var g_size: f32 = a_size;

g_point.y /= g_ratio;
g_point = ((g_point - vec2<f32>(0.5)) / vec2<f32>(g_size));
var g_q: f32 = (((sqrt(3.0) / 3.0) * g_point.x) + (((-1.0) / 3.0) * g_point.y));
var g_r: f32 = ((0.0 * g_point.x) + ((2.0 / 3.0) * g_point.y));
var g_hex: g_Hexagon = g_createHexagon(g_q, g_r);
return g_roundHexagon(g_hex);
}
fn g_pointFromHexagon(a_hex: g_Hexagon, a_size: f32) -> vec2<f32> {
var g_hex: g_Hexagon = a_hex;
var g_size: f32 = a_size;

var g_x: f32 = ((((sqrt(3.0) * g_hex.g_q) + ((sqrt(3.0) / 2.0) * g_hex.g_r)) * g_size) + 0.5);
var g_y: f32 = ((((0.0 * g_hex.g_q) + ((3.0 / 2.0) * g_hex.g_r)) * g_size) + 0.5);
return vec2<f32>(g_x, (g_y * g_ratio));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_dist: f32 = (2.0 * min(g_progress, (1.0 - g_progress)));
g_dist = select(g_dist, (ceil((g_dist * f32(f32(g_steps)))) / f32(f32(g_steps))), (g_steps > 0));
var g_size: f32 = (((sqrt(3.0) / 3.0) * g_dist) / g_horizontalHexagons);
var g_point: vec2<f32> = select(g_uv, g_pointFromHexagon(g_hexagonFromPoint(g_uv, g_size), g_size), (g_dist > 0.0));
return mix(getFromColor(g_point), getToColor(g_point), vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_steps = i32(params.steps);
g_horizontalHexagons = params.horizontalHexagons;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
