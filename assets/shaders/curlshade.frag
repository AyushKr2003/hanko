// The desk under the unlock cut (curl.vert): where a half has rolled off,
// a soft shade on the desk beside the roll, deepest at the roll and gone a
// little way toward the cut, so the paper reads as lifted off the screen.
// Rebuild: scripts/hanko-shaders
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 screen;
    float tilt;
    float start;    // the fold at which a half begins to lift (px)
    float foldA;    // above the cut
    float radiusA;
    float foldB;    // below
    float radiusB;
};

float shade(vec2 p, float side, float fold, float r) {
    float hyp = length(screen);
    vec2 c = 0.5 * screen;
    vec2 along = vec2(screen.x, -screen.y) / hyp;
    vec2 out0 = vec2(screen.y, screen.x) / hyp;
    if (side * dot(p - c, out0) < 0.0) return 0.0;
    vec2 n = side * (out0 * cos(tilt) + along * sin(tilt));
    float q = dot(p - c, n);
    if (q > fold) return 0.0;
    r = max(r, 1.0);
    float lift = clamp((fold - start) / (3.14159265 * r), 0.0, 1.0);
    return 0.34 * lift * exp(-max(fold - r - q, 0.0) / (1.6 * r));
}

void main() {
    vec2 p = qt_TexCoord0 * screen;
    float a = max(shade(p, -1.0, foldA, radiusA), shade(p, 1.0, foldB, radiusB));
    fragColor = vec4(0.0, 0.0, 0.0, a) * qt_Opacity;
}
