#version 300 es
// Sumi 墨, ink only (docs/kaze, mockup 11): the whole screen in ink, through
// a film S-curve, with a fixed paper grain and a soft vignette. Colours of
// the theme's red keep their colour, so "you" and "now" still show.
// `hanko sumi on` writes this file with SEAL set to the theme's red.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const vec3 SEAL = vec3(0.847, 0.271, 0.184);   // replaced by `hanko sumi on`
const float CURVE = 0.6;      // how much of the S-curve (0 = straight)
const float GRAIN = 0.035;    // grain strength; fixed, so the screen stays still
const float VIGNETTE = 0.45;

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

void main() {
  vec4 c = texture(tex, v_texcoord);
  float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
  float s = mix(l, l * l * (3.0 - 2.0 * l), CURVE);
  vec2 px = v_texcoord * vec2(textureSize(tex, 0));
  float g = (hash12(floor(px)) - 0.5) * GRAIN;
  vec2 d = v_texcoord - 0.5;
  float v = 1.0 - dot(d, d) * VIGNETTE;
  vec3 ink = vec3(clamp(s + g, 0.0, 1.0) * v);
  // Keep a pixel whose colour leans the way the theme's red does, however
  // light or dark: thin red marks blend into their ground at the edges, so
  // a plain colour distance would turn them grey.
  vec3 lum = vec3(0.2126, 0.7152, 0.0722);
  vec3 cv = c.rgb - vec3(l), sv = SEAL - vec3(dot(SEAL, lum));
  float chroma = length(cv);
  float lean = dot(cv / max(chroma, 1e-5), normalize(sv));
  float keep = smoothstep(0.86, 0.96, lean) * smoothstep(0.035, 0.09, chroma);
  fragColor = vec4(mix(ink, c.rgb, keep), c.a);
}
