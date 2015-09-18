#define M_PI 3.1415926535897932384626433832795

precision mediump float;

attribute vec4 aPosition;
attribute vec3 aNormal;
uniform vec3 uAngles;
uniform vec2 uSurfaceSize;

varying lowp vec4 vColor;

vec3 lightPosition = vec3(0.6, 0.8, 1.0);
vec4 diffuseColor = vec4(0.4, 0.7, 1.0, 1.0);

vec3 angles = uAngles * M_PI * 2.0;

float maxwh = max(uSurfaceSize.x, uSurfaceSize.y);
mat4 matScalePixelsSquare = mat4(uSurfaceSize.y/maxwh, 0.0,                  0.0, 0.0,
                                 0.0,                  uSurfaceSize.x/maxwh, 0.0, 0.0,
                                 0.0,                  0.0,                  1.0, 0.0,
                                 0.0,                  0.0,                  0.0, 1.0);

mat4 matScaleDownTwice    = mat4(0.5, 0.0, 0.0, 0.0,
                                 0.0, 0.5, 0.0, 0.0,
                                 0.0, 0.0, 0.5, 0.0,
                                 0.0, 0.0, 0.0, 1.0);

mat4 matMove              = mat4(1.0, 0.0, 0.0, 0.0,
                                 0.0, 1.0, 0.0, 0.0,
                                 0.0, 0.0, 1.0, 0.0,
                                 0.0, 0.5, 1.0, 1.0);

mat4 matRotateX           = mat4( 1.0,  0.0,           0.0,           0.0,
                                  0.0,  cos(angles.x), sin(angles.x), 0.0,
                                  0.0, -sin(angles.x), cos(angles.x), 0.0,
                                  0.0,  0.0,           0.0,           1.0);

mat4 matRotateY           = mat4( cos(angles.y), 0.0, -sin(angles.y), 0.0,
                                  0.0,           1.0,  0.0,           0.0,
                                  sin(angles.y), 0.0,  cos(angles.y), 0.0,
                                  0.0,           0.0,  0.0,           1.0);

mat4 matRotateZ           = mat4( cos(angles.z), sin(angles.z),  0.0, 0.0,
                                 -sin(angles.z), cos(angles.z),  0.0, 0.0,
                                  0.0,           0.0,            1.0, 0.0,
                                  0.0,           0.0,            0.0, 1.0);

void main()
{
    float nDotVP = abs(dot(normalize(aNormal), normalize(lightPosition)));
    vColor = diffuseColor * nDotVP;

    mat4 mat = mat4(1.0) * matScalePixelsSquare * matScaleDownTwice * matRotateX * matRotateY * matRotateZ * matMove;
    gl_Position = mat * aPosition;
}
