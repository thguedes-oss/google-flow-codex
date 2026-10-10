// Ported from InvertedPageCurl.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 94b573f129dcff2d85e106fd1c3193671d3dfe08f4d3fcd48bfa7bcc59a59858
// Original authors: Hewlett-Packard
// License: BSD 3 Clause; full original notices in ../originals/InvertedPageCurl.glsl and ../LICENSE
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
var<private> g_MIN_AMOUNT: f32;
var<private> g_MAX_AMOUNT: f32;
var<private> g_PI: f32;
var<private> g_scale: f32;
var<private> g_sharpness: f32;
var<private> g_cylinderRadius: f32;
var<private> g_amount: f32;
var<private> g_cylinderCenter: f32;
var<private> g_cylinderAngle: f32;
fn g_hitPoint(a_hitAngle: f32, a_yc: f32, a_point: vec3<f32>, a_rrotation: mat3x3<f32>) -> vec3<f32> {
var g_hitAngle: f32 = a_hitAngle;
var g_yc: f32 = a_yc;
var g_point: vec3<f32> = a_point;
var g_rrotation: mat3x3<f32> = a_rrotation;

var g_hitPoint: f32 = (g_hitAngle / (2.0 * g_PI));
g_point.y = g_hitPoint;
return (g_rrotation * g_point);
}
fn g_antiAlias(a_color1: vec4<f32>, a_color2: vec4<f32>, a_distanc: f32) -> vec4<f32> {
var g_color1: vec4<f32> = a_color1;
var g_color2: vec4<f32> = a_color2;
var g_distanc: f32 = a_distanc;

g_distanc *= g_scale;
if ((g_distanc < 0.0)) {
return g_color2;
}
if ((g_distanc > 2.0)) {
return g_color1;
}
var g_dd: f32 = pow((1.0 - (g_distanc / 2.0)), g_sharpness);
return (((g_color2 - g_color1) * vec4<f32>(g_dd)) + g_color1);
}
fn g_distanceToEdge(a_point: vec3<f32>) -> f32 {
var g_point: vec3<f32> = a_point;

var g_dx: f32 = abs(select(g_point.x, (1.0 - g_point.x), (g_point.x > 0.5)));
var g_dy: f32 = abs(select(g_point.y, (1.0 - g_point.y), (g_point.y > 0.5)));
if ((g_point.x < 0.0)) {
g_dx = (-g_point.x);
}
if ((g_point.x > 1.0)) {
g_dx = (g_point.x - 1.0);
}
if ((g_point.y < 0.0)) {
g_dy = (-g_point.y);
}
if ((g_point.y > 1.0)) {
g_dy = (g_point.y - 1.0);
}
if ((((g_point.x < 0.0) || (g_point.x > 1.0)) && ((g_point.y < 0.0) || (g_point.y > 1.0)))) {
return sqrt(((g_dx * g_dx) + (g_dy * g_dy)));
}
return min(g_dx, g_dy);
}
fn g_seeThrough(a_yc: f32, a_p: vec2<f32>, a_rotation: mat3x3<f32>, a_rrotation: mat3x3<f32>) -> vec4<f32> {
var g_yc: f32 = a_yc;
var g_p: vec2<f32> = a_p;
var g_rotation: mat3x3<f32> = a_rotation;
var g_rrotation: mat3x3<f32> = a_rrotation;

var g_hitAngle: f32 = (g_PI - (acos(clamp((g_yc / g_cylinderRadius), (-1.0), 1.0)) - g_cylinderAngle));
var g_point: vec3<f32> = g_hitPoint(g_hitAngle, g_yc, (g_rotation * vec3<f32>(g_p, 1.0)), g_rrotation);
if (((g_yc <= 0.0) && ((((g_point.x < 0.0) || (g_point.y < 0.0)) || (g_point.x > 1.0)) || (g_point.y > 1.0)))) {
return getToColor(g_p);
}
if ((g_yc > 0.0)) {
return getFromColor(g_p);
}
var g_color: vec4<f32> = getFromColor(g_point.xy);
var g_tcolor: vec4<f32> = vec4<f32>(0.0);
return g_antiAlias(g_color, g_tcolor, g_distanceToEdge(g_point));
}
fn g_seeThroughWithShadow(a_yc: f32, a_p: vec2<f32>, a_point: vec3<f32>, a_rotation: mat3x3<f32>, a_rrotation: mat3x3<f32>) -> vec4<f32> {
var g_yc: f32 = a_yc;
var g_p: vec2<f32> = a_p;
var g_point: vec3<f32> = a_point;
var g_rotation: mat3x3<f32> = a_rotation;
var g_rrotation: mat3x3<f32> = a_rrotation;

var g_shadow: f32 = (g_distanceToEdge(g_point) * 30.0);
g_shadow = ((1.0 - g_shadow) / 3.0);
if ((g_shadow < 0.0)) {
g_shadow = 0.0;
} else {
g_shadow *= g_amount;
}
var g_shadowColor: vec4<f32> = g_seeThrough(g_yc, g_p, g_rotation, g_rrotation);
g_shadowColor.r -= g_shadow;
g_shadowColor.g -= g_shadow;
g_shadowColor.b -= g_shadow;
return g_shadowColor;
}
fn g_backside(a_yc: f32, a_point: vec3<f32>) -> vec4<f32> {
var g_yc: f32 = a_yc;
var g_point: vec3<f32> = a_point;

var g_color: vec4<f32> = getFromColor(g_point.xy);
var g_gray: f32 = (((g_color.r + g_color.b) + g_color.g) / 15.0);
g_gray += ((8.0 / 10.0) * ((pow(max(0.0, (1.0 - abs((g_yc / g_cylinderRadius)))), (2.0 / 10.0)) / 2.0) + (5.0 / 10.0)));
g_color = vec4<f32>((vec3<f32>(g_gray)).x, (vec3<f32>(g_gray)).y, (vec3<f32>(g_gray)).z, g_color.w);
return g_color;
}
fn g_behindSurface(a_p: vec2<f32>, a_yc: f32, a_point: vec3<f32>, a_rrotation: mat3x3<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_yc: f32 = a_yc;
var g_point: vec3<f32> = a_point;
var g_rrotation: mat3x3<f32> = a_rrotation;

var g_safeAmount: f32 = select(min(g_amount, (-1e-4)), max(g_amount, 1e-4), (g_amount >= 0.0));
var g_shado: f32 = ((1.0 - ((((-g_cylinderRadius) - g_yc) / g_safeAmount) * 7.0)) / 6.0);
g_shado *= (1.0 - abs((g_point.x - 0.5)));
g_yc = (((-g_cylinderRadius) - g_cylinderRadius) - g_yc);
var g_hitAngle: f32 = ((acos(clamp((g_yc / g_cylinderRadius), (-1.0), 1.0)) + g_cylinderAngle) - g_PI);
g_point = g_hitPoint(g_hitAngle, g_yc, g_point, g_rrotation);
if (((((((g_yc < 0.0) && (g_point.x >= 0.0)) && (g_point.y >= 0.0)) && (g_point.x <= 1.0)) && (g_point.y <= 1.0)) && ((g_hitAngle < g_PI) || (g_amount > 0.5)))) {
var g_dx: f32 = (g_point.x - 0.5);
var g_dy: f32 = (g_point.y - 0.5);
g_shado = (1.0 - (sqrt(((g_dx * g_dx) + (g_dy * g_dy))) / (71.0 / 100.0)));
var g_nyc: f32 = ((-g_yc) / g_cylinderRadius);
g_shado *= ((g_nyc * g_nyc) * g_nyc);
g_shado *= 0.5;
} else {
g_shado = 0.0;
}
return vec4<f32>((getToColor(g_p).rgb - vec3<f32>(g_shado)), 1.0);
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

g_amount = ((g_progress * (g_MAX_AMOUNT - g_MIN_AMOUNT)) + g_MIN_AMOUNT);
g_cylinderCenter = g_amount;
g_cylinderAngle = ((2.0 * g_PI) * g_amount);
var g_angle: f32 = ((100.0 * g_PI) / 180.0);
var g_c: f32 = cos((-g_angle));
var g_s: f32 = sin((-g_angle));
var g_rotation: mat3x3<f32> = mat3x3<f32>(vec3<f32>(g_c, g_s, f32(0)), vec3<f32>((-g_s), g_c, f32(0)), vec3<f32>((-0.801), 0.8900, f32(1)));
g_c = cos(g_angle);
g_s = sin(g_angle);
var g_rrotation: mat3x3<f32> = mat3x3<f32>(vec3<f32>(g_c, g_s, f32(0)), vec3<f32>((-g_s), g_c, f32(0)), vec3<f32>(0.98500, 0.985, f32(1)));
var g_point: vec3<f32> = (g_rotation * vec3<f32>(g_p, 1.0));
var g_yc: f32 = (g_point.y - g_cylinderCenter);
if ((g_yc < (-g_cylinderRadius))) {
return g_behindSurface(g_p, g_yc, g_point, g_rrotation);
}
if ((g_yc > g_cylinderRadius)) {
return getFromColor(g_p);
}
var g_hitAngle: f32 = ((acos(clamp((g_yc / g_cylinderRadius), (-1.0), 1.0)) + g_cylinderAngle) - g_PI);
var g_hitAngleMod: f32 = (g_hitAngle - (2.0 * g_PI) * floor(g_hitAngle / (2.0 * g_PI)));
if ((((g_hitAngleMod > g_PI) && (g_amount < 0.5)) || ((g_hitAngleMod > (g_PI / 2.0)) && (g_amount < 0.0)))) {
return g_seeThrough(g_yc, g_p, g_rotation, g_rrotation);
}
g_point = g_hitPoint(g_hitAngle, g_yc, g_point, g_rrotation);
if (((((g_point.x < 0.0) || (g_point.y < 0.0)) || (g_point.x > 1.0)) || (g_point.y > 1.0))) {
return g_seeThroughWithShadow(g_yc, g_p, g_point, g_rotation, g_rrotation);
}
var g_color: vec4<f32> = g_backside(g_yc, g_point);
var g_otherColor: vec4<f32>;
if ((g_yc < 0.0)) {
var g_dx2: f32 = (g_point.x - 0.5);
var g_dy2: f32 = (g_point.y - 0.5);
var g_shado: f32 = (1.0 - (sqrt(((g_dx2 * g_dx2) + (g_dy2 * g_dy2))) / 0.71));
var g_nyc2: f32 = ((-g_yc) / g_cylinderRadius);
g_shado *= ((g_nyc2 * g_nyc2) * g_nyc2);
g_shado *= 0.5;
g_otherColor = vec4<f32>(0.0, 0.0, 0.0, g_shado);
} else {
g_otherColor = getFromColor(g_p);
}
g_color = g_antiAlias(g_color, g_otherColor, (g_cylinderRadius - abs(g_yc)));
var g_cl: vec4<f32> = g_seeThroughWithShadow(g_yc, g_p, g_point, g_rotation, g_rrotation);
var g_dist: f32 = g_distanceToEdge(g_point);
return g_antiAlias(g_color, g_cl, g_dist);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_MIN_AMOUNT = (-0.16);
g_MAX_AMOUNT = 1.5;
g_PI = 3.141592653589793;
g_scale = 512.0;
g_sharpness = 3.0;
g_cylinderRadius = ((1.0 / g_PI) / 2.0);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
