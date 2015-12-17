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

#import "GameViewController.h"
#import "AppController.h"

@interface GameViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) AppController *app;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.app = [[AppController alloc] initWithAppContext:nil onSurface:self];
}

- (void)dealloc
{
    [self.app destroy];
    self.app = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        [self.app destroy];
        self.app = nil;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - UIResponder delegate methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        CGPoint point = [aTouch locationInView:self.view];
        [self.app touchBegan:point];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        CGPoint point = [aTouch locationInView:self.view];
        [self.app touchMoved:point];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        CGPoint point = [aTouch locationInView:self.view];
        [self.app touchEnded:point];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        CGPoint point = [aTouch locationInView:self.view];
        [self.app touchCancelled:point];
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [self.app update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.app draw];
}

#pragma mark - Surface delegate methods

- (void)initGL:(APPGLColorFormat)colorFormat depth:(APPGLDepthFormat)depthFormat {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context)
        @throw [NSException exceptionWithName:@"EAGLContextCreationError" reason:@"Failed to create ES context" userInfo:nil];

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;

    switch (colorFormat) {
        case APPGLColorFormatRGB565:
            view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
            break;
        case APPGLColorFormatRGBA8888:
            view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
            break;
        default:
            @throw [NSException exceptionWithName:@"WrongColorFormat"
                                           reason:[NSString stringWithFormat:@"Unsupported color format: %d", (int)colorFormat]
                                         userInfo:nil];
    }

    switch (depthFormat) {
        case APPGLDepthFormatNone:
            view.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
            break;
        case APPGLDepthFormat16:
            view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
            break;
        case APPGLDepthFormat24:
            view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
            break;
        default:
            @throw [NSException exceptionWithName:@"WrongDepthFormat"
                                           reason:[NSString stringWithFormat:@"Unsupported depth format: %d", (int)depthFormat]
                                         userInfo:nil];
    }

    [EAGLContext setCurrentContext:self.context];
}

- (void)deinitGL {
    [EAGLContext setCurrentContext:nil];
    self.context = nil;
}

- (CGSize)surfaceSize {
    return CGSizeMake([(GLKView*)self.view drawableWidth], [(GLKView*)self.view drawableHeight]);
}

@end
