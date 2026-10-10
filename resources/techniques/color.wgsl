// Independent FLOW image treatment. No BeatCut code incorporated.
struct VertexInput { @location(0) position: vec2<f32>, @location(1) tex_coords: vec2<f32>, @location(2) color: vec4<f32> };
struct VertexOutput { @builtin(position) clip_position: vec4<f32>, @location(0) tex_coords: vec2<f32> };
@vertex fn vs_main(input: VertexInput) -> VertexOutput {
  var out: VertexOutput; out.clip_position = vec4<f32>(input.position, 0.0, 1.0); out.tex_coords = input.tex_coords; return out;
}
struct Params { brightness: f32, contrast: f32, saturation: f32, vignette: f32 };
@group(0) @binding(0) var content: texture_2d<f32>;
@group(0) @binding(1) var tex_sampler: sampler;
@group(0) @binding(2) var<uniform> params: Params;
@fragment fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
  let pixel = textureSample(content, tex_sampler, input.tex_coords);
  let straight = pixel.rgb / max(pixel.a, 0.00001);
  let gray = vec3<f32>(dot(straight, vec3<f32>(0.2126, 0.7152, 0.0722)));
  var rgb = (mix(gray, straight, params.saturation) - vec3<f32>(0.5)) * params.contrast + vec3<f32>(0.5 + params.brightness);
  let radius = length(input.tex_coords - vec2<f32>(0.5)) / 0.707107;
  rgb *= 1.0 - params.vignette * smoothstep(0.25, 1.0, radius);
  return vec4<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0)) * pixel.a, pixel.a);
}
