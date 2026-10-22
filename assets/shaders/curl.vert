// Taiji 対峙, the unlock cut (plugins/hanko.desk): one half of the lock's
// picture, peeled off the screen from the cut like a page turned in a book.
// The sheet does not hinge on creases; it rolls round a cylinder (radius
// `radius`) lying on the screen, whose axis moves out from the cut (`fold`,
// measured along the half's outward direction, tilted by `tilt` so one end
// of the cut lifts first). Paper behind the axis wraps round it and lies
// back over the rest, face down. The mesh's last rows are the cut, so the
// paper that rolls highest is drawn last, over what it covers.
// core/Taiji.js cutCurl() gives fold, radius and tilt. Rebuild:
// scripts/hanko-shaders
#version 440
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 uv;      // where this paper lay, on the screen (0..1)
layout(location = 1) out float theta;  // how far round the roll (0 flat, pi face down)
layout(location = 2) out float lay;    // its distance past the axis while flat (px)
layout(location = 3) out float cut;    // its distance from the cut while flat (px)
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 screen;   // px
    float side;    // +1 the half below the cut, -1 above
    float fold;    // the roll's axis, from the screen's centre (px)
    float radius;  // px
    float tilt;    // radians
    float eye;     // px: how near the eye is, so a lifting sheet swells
    vec4 back;     // the back of the sheet
};

void main() {
    float hyp = length(screen);
    float reach = screen.x * screen.y / hyp;
    vec2 c = 0.5 * screen;
    vec2 along = vec2(screen.x, -screen.y) / hyp;
    vec2 out0 = vec2(screen.y, screen.x) / hyp;
    // this vertex flat: along the cut, and out from it
    float u = (qt_MultiTexCoord0.x - 0.5) * hyp;
    float d = (1.0 - qt_MultiTexCoord0.y) * reach;
    vec2 p = c + side * (along * u + out0 * d);
    uv = p / screen;
    vec2 n = side * (out0 * cos(tilt) + along * sin(tilt));
    float q = dot(p - c, n);
    float s = fold - q;
    float to = q;
    float z = 0.0;
    float th = 0.0;
    if (s > 0.0) {
        float r = max(radius, 1.0);
        float halfway = 3.14159265 * r;
        if (s < halfway) {
            th = s / r;
            to = fold - r * sin(th);
            z = r * (1.0 - cos(th));
        } else {
            th = 3.14159265;
            to = fold + (s - halfway);
            z = 2.0 * r;
        }
    }
    theta = th;
    cut = d;
    lay = q - fold;
    vec2 at = p + n * (to - q);
    at = c + (at - c) * eye / max(eye - z, 1.0);
    gl_Position = qt_Matrix * vec4(at, 0.0, 1.0);
}
