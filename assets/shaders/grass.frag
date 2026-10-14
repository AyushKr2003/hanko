// Kaze 風: the grass bends in the wind (hanko.background). The grass is drawn
// once per lean on a Canvas; this shifts each row of it sideways by a wave
// that runs downwind, the roots still and the tips moving most, so a windy
// desk costs the GPU a strip and the CPU one number a frame. The wave is
// core/Wind.js ripple(); Wind.rippleUniforms() gives amp, freq and dir.
// Rebuild: scripts/hanko-shaders
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;   // seconds
    float amp;    // the tips' furthest shift, as a share of the width
    float freq;   // Hz
    float dir;    // +1 the wind leans right, -1 left
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;
    float up = 1.0 - uv.y;
    float p = 6.2831853 * (freq * time - dir * uv.x * 2.6);
    float wave = 0.65 * sin(p) + 0.35 * sin(1.7 * p + 1.3);
    float x = uv.x - dir * amp * up * up * wave;
    if (x < 0.0 || x > 1.0) { fragColor = vec4(0.0); return; }
    fragColor = texture(source, vec2(x, uv.y)) * qt_Opacity;
}
