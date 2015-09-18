/*
 * Copyright (c) 2011-2015 CrystaX .NET.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY CrystaX .NET ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CrystaX .NET OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are those of the
 * authors and should not be interpreted as representing official policies, either expressed
 * or implied, of CrystaX .NET.
 */

#import "AppController.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const GLfloat CUBE_VERTEX_DATA[] = {
     // Data layout for each line below is:
     // posX, posY, posZ,       normalX, normalY, normalZ
     0.5f, -0.5f, -0.5f,        1.0f,  0.0f,  0.0f,
     0.5f,  0.5f, -0.5f,        1.0f,  0.0f,  0.0f,
     0.5f, -0.5f,  0.5f,        1.0f,  0.0f,  0.0f,
     0.5f, -0.5f,  0.5f,        1.0f,  0.0f,  0.0f,
     0.5f,  0.5f, -0.5f,        1.0f,  0.0f,  0.0f,
     0.5f,  0.5f,  0.5f,        1.0f,  0.0f,  0.0f,

     0.5f,  0.5f, -0.5f,        0.0f,  1.0f,  0.0f,
    -0.5f,  0.5f, -0.5f,        0.0f,  1.0f,  0.0f,
     0.5f,  0.5f,  0.5f,        0.0f,  1.0f,  0.0f,
     0.5f,  0.5f,  0.5f,        0.0f,  1.0f,  0.0f,
    -0.5f,  0.5f, -0.5f,        0.0f,  1.0f,  0.0f,
    -0.5f,  0.5f,  0.5f,        0.0f,  1.0f,  0.0f,

    -0.5f,  0.5f, -0.5f,       -1.0f,  0.0f,  0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f,  0.0f,  0.0f,
    -0.5f,  0.5f,  0.5f,       -1.0f,  0.0f,  0.0f,
    -0.5f,  0.5f,  0.5f,       -1.0f,  0.0f,  0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f,  0.0f,  0.0f,
    -0.5f, -0.5f,  0.5f,       -1.0f,  0.0f,  0.0f,

    -0.5f, -0.5f, -0.5f,        0.0f, -1.0f,  0.0f,
     0.5f, -0.5f, -0.5f,        0.0f, -1.0f,  0.0f,
    -0.5f, -0.5f,  0.5f,        0.0f, -1.0f,  0.0f,
    -0.5f, -0.5f,  0.5f,        0.0f, -1.0f,  0.0f,
     0.5f, -0.5f, -0.5f,        0.0f, -1.0f,  0.0f,
     0.5f, -0.5f,  0.5f,        0.0f, -1.0f,  0.0f,

     0.5f,  0.5f,  0.5f,        0.0f,  0.0f,  1.0f,
    -0.5f,  0.5f,  0.5f,        0.0f,  0.0f,  1.0f,
     0.5f, -0.5f,  0.5f,        0.0f,  0.0f,  1.0f,
     0.5f, -0.5f,  0.5f,        0.0f,  0.0f,  1.0f,
    -0.5f,  0.5f,  0.5f,        0.0f,  0.0f,  1.0f,
    -0.5f, -0.5f,  0.5f,        0.0f,  0.0f,  1.0f,

     0.5f, -0.5f, -0.5f,        0.0f,  0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,        0.0f,  0.0f, -1.0f,
     0.5f,  0.5f, -0.5f,        0.0f,  0.0f, -1.0f,
     0.5f,  0.5f, -0.5f,        0.0f,  0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,        0.0f,  0.0f, -1.0f,
    -0.5f,  0.5f, -0.5f,        0.0f,  0.0f, -1.0f,
};

static const GLuint CUBE_VERTEX_COUNT = sizeof(CUBE_VERTEX_DATA)/(sizeof(CUBE_VERTEX_DATA[0]) * 6);

static const char *glerror(GLint error) {
    switch (error) {
#define CASE(e) case e: return #e
        CASE(GL_NO_ERROR);
        CASE(GL_INVALID_ENUM);
        CASE(GL_INVALID_VALUE);
        CASE(GL_INVALID_OPERATION);
        CASE(GL_OUT_OF_MEMORY);
#undef CASE
        default: return "UNKNOWN";
    }
}

static void checkGlError(const char *op) {
    BOOL hasErrors = NO;
    for (GLint error = glGetError(); error != GL_NO_ERROR; error = glGetError()) {
        hasErrors = YES;
        NSLog(@"*** OPENGL ERROR: after %s(): %s (0x%x)", op, glerror(error), error);
    }
    if (hasErrors)
        @throw [NSException exceptionWithName:@"OpenGLError" reason:[NSString stringWithFormat:@"OpenGL error after %s()", op] userInfo:nil];
}

static GLfloat incangle(GLfloat val, GLfloat delta)
{
    val += delta;
    if (val < 0.0) return 1.0;
    if (val > 1.0) return 0.0;
    return val;
}

@interface AppController () {
    GLfloat angles[3];
    uint64_t lt;
    BOOL paused;
    CGPoint touchPoint;

    GLuint program;

    GLuint vertexArray;
    GLuint vertexBuffer;

    GLint aPosition;
    GLint aNormal;
    GLint uAngles;
    GLint uSurfaceSize;

    void *appcontext;
}

@property (strong, nonatomic) id<Surface> surface;

@end

@implementation AppController

- (instancetype)initWithAppContext:(void*)appctx onSurface:(id<Surface>)sfc {
    self = [super init];
    if (!self)
        return nil;

    angles[0] = 0;
    angles[1] = 0;
    angles[2] = 0;

    lt = 0;
    paused = NO;
    touchPoint = CGPointZero;

    appcontext = appctx;
    self.surface = sfc;

    [self.surface initGL:APPGLColorFormatRGBA8888 depth:APPGLDepthFormat24];

    NSLog(@"VENDOR: %s", glGetString(GL_VENDOR));
    NSLog(@"RENDERER: %s", glGetString(GL_RENDERER));
    NSLog(@"VERSION: %s", glGetString(GL_VERSION));
    NSLog(@"GLSL VERSION: %s", glGetString(GL_SHADING_LANGUAGE_VERSION));

    glEnable(GL_DEPTH_TEST);
    checkGlError("glDisable");

    glGenVertexArraysOES(1, &vertexArray);
    checkGlError("glGenVertexArrayOES");
    glBindVertexArrayOES(vertexArray);
    checkGlError("glBindVertexArrayOES");

    glGenBuffers(1, &vertexBuffer);
    checkGlError("glGenBuffers");
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    checkGlError("glBindBuffer");
    glBufferData(GL_ARRAY_BUFFER, sizeof(CUBE_VERTEX_DATA), CUBE_VERTEX_DATA, GL_STATIC_DRAW);
    checkGlError("glBufferData");

    glEnableVertexAttribArray(0);
    checkGlError("glEnableVertexAttribArray");
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    checkGlError("glVertexAttribPointer");

    glEnableVertexAttribArray(1);
    checkGlError("glEnableVertexAttribArray");
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    checkGlError("glVertexAttribPointer");

    [self loadShaders:@"shader.vsh" andFragment:@"shader.fsh"];

    return self;
}

- (void)destroy {
    glDeleteBuffers(1, &vertexBuffer);
    checkGlError("glDeleteBuffers");
    glDeleteVertexArraysOES(1, &vertexArray);
    checkGlError("glDeleteVertexArrayOES");

    if (program) {
        glDeleteProgram(program);
        checkGlError("glDeleteProgram");
        program = 0;
    }

    [self.surface deinitGL];
    self.surface = nil;
}

- (void)update {
    uint64_t ct = [[Platform sharedInstance] monotime];

    if (lt != 0 && !paused) {
        GLfloat delta = ((float)(ct - lt))/1000000;
        angles[0] = incangle(angles[0], delta/15);
        angles[1] = incangle(angles[1], delta/3);
        angles[2] = incangle(angles[2], delta/10);
    }

    lt = ct;
}

- (void)draw {
    glClearColor(0.65f, 0.65f, 0.65f, 1);
    checkGlError("glClearColor");
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    checkGlError("glClear");

    glUseProgram(program);
    checkGlError("glUseProgram");

    CGSize ss = [self.surface surfaceSize];
    glUniform2f(uSurfaceSize, ss.width, ss.height);
    checkGlError("glUniform2f");

    glUniform3fv(uAngles, 1, angles);
    checkGlError("glUniform2fv");

    glDrawArrays(GL_TRIANGLES, 0, CUBE_VERTEX_COUNT);
    checkGlError("glDrawArrays");
}

- (BOOL)loadShaders:(NSString *)vertShaderName andFragment:(NSString *)fragShaderName {
    GLuint vertShader = 0, fragShader = 0;

    @try {
        vertShader = [self loadShader:vertShaderName ofType:GL_VERTEX_SHADER];
        if (vertShader == 0) return NO;
        fragShader = [self loadShader:fragShaderName ofType:GL_FRAGMENT_SHADER];
        if (fragShader == 0) return NO;

        // Create shader program.
        program = glCreateProgram();
        checkGlError("glCreateProgram");
        if (program == 0) {
            NSLog(@"Failed to create GL program");
            return 0;
        }

        // Attach vertex shader to program.
        glAttachShader(program, vertShader);
        checkGlError("glAttachShader");

        // Attach fragment shader to program.
        glAttachShader(program, fragShader);
        checkGlError("glAttachShader");

        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, 0, "aPosition");
        checkGlError("glBindAttribLocation");

        glBindAttribLocation(program, 1, "aNormal");
        checkGlError("glBindAttribLocation");

        // Link program.
        if (![self linkProgram:program]) {
            glDeleteProgram(program);
            checkGlError("glDeleteProgram");
            program = 0;
            return NO;
        }

        aPosition = glGetAttribLocation(program, "aPosition");
        checkGlError("glGetAttribLocation");

        aNormal = glGetAttribLocation(program, "aNormal");
        checkGlError("glGetAttribLocation");

        uAngles = glGetUniformLocation(program, "uAngles");
        checkGlError("glGetAttribLocation");

        uSurfaceSize = glGetUniformLocation(program, "uSurfaceSize");
        checkGlError("glGetUniformLocation");

        return YES;
    }
    @finally {
        if (vertShader != 0) {
            glDetachShader(program, vertShader);
            checkGlError("glDetachShader");
            glDeleteShader(vertShader);
            checkGlError("glDeleteShader");
        }
        if (fragShader != 0) {
            glDetachShader(program, fragShader);
            checkGlError("glDetachShader");
            glDeleteShader(fragShader);
            checkGlError("glDeleteShader");
        }
    }
}

- (GLuint)loadShader:(NSString*)shaderName ofType:(GLenum)type {
    NSData *source = [[Platform sharedInstance] loadResource:shaderName withAppContext:appcontext];
    if (!source) {
        NSLog(@"Failed to load shader '%@'", shaderName);
        return 0;
    }

    NSString *ssource = [[NSString alloc] initWithData:source encoding:NSUTF8StringEncoding];

    GLuint shader = glCreateShader(type);
    checkGlError("glCreateShader");
    if (shader == 0) {
        NSLog(@"Failed to create shader '%@'", shaderName);
        return 0;
    }

    const GLchar *src = [ssource UTF8String];
    glShaderSource(shader, 1, &src, NULL);
    checkGlError("glShaderSource");
    glCompileShader(shader);
    checkGlError("glCompileShader");

    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    checkGlError("glGetShaderiv");
    if (compiled)
        return shader;

    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    checkGlError("glGetShaderiv");
    if (logLength > 0) {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        checkGlError("glGetShaderInfoLog");
        NSLog(@"Failed to compile shader '%@':\n%s", shaderName, log);
        free(log);
    }
    else {
        NSLog(@"Failed to compile shader '%@'", shaderName);
    }
    glDeleteShader(shader);
    checkGlError("glDeleteShader");
    return 0;
}

- (BOOL)linkProgram:(GLuint)prog
{
    glLinkProgram(prog);
    checkGlError("glLinkProgram");

    GLint linked;
    glGetProgramiv(prog, GL_LINK_STATUS, &linked);
    checkGlError("glGetProgramiv");
    if (linked)
        return YES;

    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    checkGlError("glGetProgramiv");
    if (logLength > 0) {
        NSLog(@"logLength=%d", logLength);
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        checkGlError("glGetProgramInfoLog");
        NSLog(@"Failed to link program:\n%s", log);
        free(log);
    }
    else {
        NSLog(@"Failed to link program");
    }
    return NO;
}

- (void)touchBegan:(CGPoint)point {
    paused = YES;
    touchPoint = point;
}

- (void)touchMoved:(CGPoint)point {
    CGSize delta = CGSizeMake(point.x - touchPoint.x, point.y - touchPoint.y);
    CGSize ssize = [self.surface surfaceSize];
    touchPoint = point;

    CGFloat factor = -1.0/fmin(ssize.width, ssize.height);
    angles[0] = incangle(angles[0], factor * delta.height);
    angles[1] = incangle(angles[1], factor * delta.width);
}

- (void)touchEnded:(CGPoint)point {
    paused = NO;
    touchPoint = CGPointZero;
}

- (void)touchCancelled:(CGPoint)point {
    paused = NO;
    touchPoint = CGPointZero;
}

@end
