// The paper of the unlock cut (curl.vert): the picture on its face, the
// sheet's own colour on its back with the picture faintly through it, as
// washi shows ink; lit from above and a little from the cut, so the inside
// of the roll falls into shade and its outside catches a soft gloss.
// Rebuild: scripts/hanko-shaders
#version 440
layout(location = 0) in vec2 uv;
layout(location = 1) in float theta;
layout(location = 2) in float lay;
layout(location = 3) in float cut;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 screen;
    float side;
    float fold;
    float radius;
    float tilt;
    float eye;
    vec4 back;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    // the picture and the cut's slope first, while every fragment still
    // runs, so their derivatives are smooth
    vec3 pic = texture(source, clamp(uv, 0.0, 1.0)).rgb;
    // the cut's own edge, once it lifts, a screen pixel soft: where the
    // gap it opens is thinner than a pixel it reads as one faint line, not
    // a row of single pixels; flat, it stays sharp against the other half
    float feather = clamp(cut / max(fwidth(cut), 1e-4), 0.0, 1.0);
    // only the screen's own picture; its edges a pixel soft
    vec2 px = uv * screen;
    float edge = min(min(px.x, screen.x - px.x), min(px.y, screen.y - px.y));
    if (edge < -1.0) discard;
    float cover = clamp(edge + 0.5, 0.0, 1.0);
    cover *= mix(1.0, feather, smoothstep(0.0, 0.2, theta));

    bool face = theta < 1.5707963;
    vec2 normal = vec2(sin(theta), cos(theta)) * (face ? 1.0 : -1.0);
    vec2 light = normalize(vec2(-0.45, 1.0));
    float diffuse = max(dot(normal, light), 0.0) / light.y;
    float gloss = pow(max(dot(normal, normalize(light + vec2(0.0, 1.0))), 0.0), 48.0);
    vec3 col = face ? pic : mix(back.rgb, pic, 0.08);
    float lit = 0.32 + 0.68 * diffuse;
    // flat paper just past the axis lies under the roll
    if (theta <= 0.0) lit *= 1.0 - 0.28 * exp(-max(lay, 0.0) / max(0.6 * radius, 1.0)) * clamp(radius / 24.0, 0.0, 1.0);
    col = col * lit + (face ? 0.0 : 0.16) * gloss;
    fragColor = vec4(col * cover, cover) * qt_Opacity;
}
