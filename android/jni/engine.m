/*
 * Copyright (c) 2011-2015 CrystaX.
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
 * THIS SOFTWARE IS PROVIDED BY CrystaX ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CrystaX OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are those of the
 * authors and should not be interpreted as representing official policies, either expressed
 * or implied, of CrystaX.
 */

#import "engine.h"
#import "AppController.h"

#include <EGL/egl.h>
#include <android_native_app_glue.h>

#include <GLES2/gl2ext.h>

void glGenVertexArraysOES(GLsizei n, GLuint *arrays)
{
    PFNGLGENVERTEXARRAYSOESPROC f = (PFNGLGENVERTEXARRAYSOESPROC)eglGetProcAddress("glGenVertexArraysOES");
    if (f) f(n, arrays);
}

void glDeleteVertexArraysOES(GLsizei n, const GLuint *arrays)
{
    PFNGLDELETEVERTEXARRAYSOESPROC f = (PFNGLDELETEVERTEXARRAYSOESPROC)eglGetProcAddress("glDeleteVertexArraysOES");
    if (f) f(n, arrays);
}

void glBindVertexArrayOES(GLuint array)
{
    PFNGLBINDVERTEXARRAYOESPROC f = (PFNGLBINDVERTEXARRAYOESPROC)eglGetProcAddress("glBindVertexArrayOES");
    if (f) f(array);
}

@interface Engine () {
    struct android_app* napp;

    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    CGSize surfaceSize;
}

@property (strong, nonatomic) AppController *app;

@end

@implementation Engine

- (instancetype) initWithAndroidApp:(struct android_app*)a {
    self = [super init];
    if (!self)
        return nil;

    napp = a;
    display = EGL_NO_DISPLAY;
    surface = EGL_NO_SURFACE;
    context = EGL_NO_CONTEXT;
    surfaceSize = CGSizeZero;

    self.app = nil;
    self.legacy = [[LegacyInterface alloc] init];

    return self;
}

- (void) dealloc {
    self.legacy = nil;
}

- (void)setupGL {
    self.app = [[AppController alloc] initWithAppContext:self.activity onSurface:self];
}

- (void)tearDownGL {
    [self.app destroy];
    self.app = nil;
}

- (void)render {
    if (!display)
        return;

    [self.app update];
    [self.app draw];

    eglSwapBuffers(display, surface);
}

- (ANativeWindow*)window {
    return napp->window;
}

- (ANativeActivity*)activity {
    return napp->activity;
}

- (void)touchBegan:(CGPoint)point {
    [self.app touchBegan:point];
}

- (void)touchMoved:(CGPoint)point {
    [self.app touchMoved:point];
}

- (void)touchEnded:(CGPoint)point {
    [self.app touchEnded:point];
}

- (void)touchCancelled:(CGPoint)point {
    [self.app touchCancelled:point];
}

- (void)windowResized {
    EGLint w, h;
    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);
    self.surfaceSize = CGSizeMake(w, h);
}

#pragma mark - Surface delegate methods

- (void)initGL:(APPGLColorFormat)colorFormat depth:(APPGLDepthFormat)depthFormat {
    if (!self.window)
        @throw [NSException exceptionWithName:@"NoYetWindow" reason:@"There is no yet window" userInfo:nil];

    // initialize OpenGL ES and EGL

    NSMutableArray *attribs = [NSMutableArray arrayWithArray:@[
        @(EGL_RENDERABLE_TYPE), @(EGL_OPENGL_ES2_BIT),
        @(EGL_SURFACE_TYPE),    @(EGL_WINDOW_BIT),
    ]];

    switch (colorFormat) {
        case APPGLColorFormatRGBA8888:
            [attribs addObjectsFromArray:@[
                @(EGL_RED_SIZE),   @8,
                @(EGL_GREEN_SIZE), @8,
                @(EGL_BLUE_SIZE),  @8,
                @(EGL_ALPHA_SIZE), @8,
            ]];
            break;
        case APPGLColorFormatRGB565:
            [attribs addObjectsFromArray:@[
                @(EGL_RED_SIZE),   @5,
                @(EGL_GREEN_SIZE), @6,
                @(EGL_BLUE_SIZE),  @5,
            ]];
            break;
        default:
            @throw [NSException exceptionWithName:@"WrongColorFormat"
                                           reason:[NSString stringWithFormat:@"Unsupported color format: %d", (int)colorFormat]
                                         userInfo:nil];
    }

    switch (depthFormat) {
        case APPGLDepthFormatNone:
            [attribs addObjectsFromArray:@[
                @(EGL_DEPTH_SIZE), @0,
            ]];
            break;
        case APPGLDepthFormat16:
            [attribs addObjectsFromArray:@[
                @(EGL_DEPTH_SIZE), @16,
            ]];
            break;
        case APPGLDepthFormat24:
            [attribs addObjectsFromArray:@[
                @(EGL_DEPTH_SIZE), @24,
            ]];
            break;
        default:
            @throw [NSException exceptionWithName:@"WrongDepthFormat"
                                           reason:[NSString stringWithFormat:@"Unsupported depth format: %d", (int)depthFormat]
                                         userInfo:nil];
    }

    [attribs addObject:@(EGL_NONE)];

    EGLint cfgattrs[[attribs count]];
    for (NSUInteger i = 0; i < [attribs count]; ++i)
        cfgattrs[i] = [[attribs objectAtIndex:i] intValue];

    const EGLint ctxattrs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE
    };
    EGLint w, h, format;
    EGLint numConfigs;
    EGLConfig config;

    EGLDisplay d = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    if (!eglInitialize(d, 0, 0))
        @throw [NSException exceptionWithName:@"EGLInitError" reason:@"Can't initialize EGL" userInfo:nil];

    /* Here, the application chooses the configuration it desires. In this
     * sample, we have a very simplified selection process, where we pick
     * the first EGLConfig that matches our criteria */
    if (!eglChooseConfig(d, cfgattrs, &config, 1, &numConfigs))
        @throw [NSException exceptionWithName:@"EGLChooseConfigError" reason:@"Can't choose config" userInfo:nil];

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    if (!eglGetConfigAttrib(d, config, EGL_NATIVE_VISUAL_ID, &format))
        @throw [NSException exceptionWithName:@"EGLGetConfigAttribError" reason:@"Can't get config attribute" userInfo:nil];

    ANativeWindow_setBuffersGeometry(self.window, 0, 0, format);

    EGLSurface sfc = eglCreateWindowSurface(d, config, self.window, NULL);
    EGLContext ctx = eglCreateContext(d, config, NULL, ctxattrs);

    if (eglMakeCurrent(d, sfc, sfc, ctx) == EGL_FALSE)
        @throw [NSException exceptionWithName:@"EGLMakeCurrentError" reason:@"Unable to eglMakeCurrent" userInfo:nil];

    eglQuerySurface(d, sfc, EGL_WIDTH, &w);
    eglQuerySurface(d, sfc, EGL_HEIGHT, &h);

    display = d;
    context = ctx;
    surface = sfc;
    self.surfaceSize = CGSizeMake(w, h);
}

- (void)deinitGL {
    if (display != EGL_NO_DISPLAY) {
        eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (context != EGL_NO_CONTEXT) {
            eglDestroyContext(display, context);
        }
        if (surface != EGL_NO_SURFACE) {
            eglDestroySurface(display, surface);
        }
        eglTerminate(display);
    }
    display = EGL_NO_DISPLAY;
    context = EGL_NO_CONTEXT;
    surface = EGL_NO_SURFACE;
}

- (CGSize)surfaceSize {
    return surfaceSize;
}

- (void)setSurfaceSize:(CGSize)newSize {
    NSLog(@"New surface size: %.0fx%.0f", newSize.width, newSize.height);
    surfaceSize = newSize;
}

@end
