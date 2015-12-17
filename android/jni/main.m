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

#include <android_native_app_glue.h>

#import <CoreGraphics/CoreGraphics.h> // for CGPointMake

#import "engine.h"
#import "Platform.h"

/**
 * Process the next input event.
 */
static int32_t engine_handle_input(struct android_app* app, AInputEvent* event) {
    Engine *engine = (__bridge Engine*)(app->userData);
    switch (AInputEvent_getType(event)) {
        case AINPUT_EVENT_TYPE_MOTION:
            switch (AMotionEvent_getAction(event)) {
                case AMOTION_EVENT_ACTION_DOWN:
                    [engine touchBegan:CGPointMake(AMotionEvent_getX(event, 0), AMotionEvent_getY(event, 0))];
                    return 1;
                case AMOTION_EVENT_ACTION_UP:
                    [engine touchEnded:CGPointMake(AMotionEvent_getX(event, 0), AMotionEvent_getY(event, 0))];
                    return 1;
                case AMOTION_EVENT_ACTION_MOVE:
                    [engine touchMoved:CGPointMake(AMotionEvent_getX(event, 0), AMotionEvent_getY(event, 0))];
                    return 1;
                case AMOTION_EVENT_ACTION_CANCEL:
                case AMOTION_EVENT_ACTION_OUTSIDE:
                    [engine touchCancelled:CGPointMake(AMotionEvent_getX(event, 0), AMotionEvent_getY(event, 0))];
                    return 1;
            }
            break;
    }

    return 0;
}

/**
 * Process the next main command.
 */
static void engine_handle_cmd(struct android_app* app, int32_t cmd) {
    Engine *engine = (__bridge Engine*)(app->userData);
    switch (cmd) {
        case APP_CMD_INIT_WINDOW:
            // The window is being shown, get it ready.
            [engine setupGL];
            break;
        case APP_CMD_TERM_WINDOW:
            // The window is being hidden or closed, clean it up.
            [engine tearDownGL];
            break;
        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_CONFIG_CHANGED:
            [engine windowResized];
            break;
    }
}

/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
void android_main(struct android_app* state) {
    app_dummy();

    Engine *engine = [[Engine alloc] initWithAndroidApp:state];

    state->userData = (__bridge void *)engine;
    state->onAppCmd = engine_handle_cmd;
    state->onInputEvent = engine_handle_input;

    const int MAX_FPS = 60;
    uint64_t tlast = [[Platform sharedInstance] monotime];

    while (1) {
        // Read all pending events.
        int events;
        struct android_poll_source* source;

        // We loop until all events are read, then continue
        // to draw the next frame of animation.
        while (ALooper_pollAll(0, NULL, &events, (void**)&source) >= 0) {

            // Process this event.
            if (source != NULL)
                source->process(state, source);

            // Check if we are exiting.
            if (state->destroyRequested != 0) {
                [engine tearDownGL];
                return;
            }
        }

        uint64_t tcur = [[Platform sharedInstance] monotime];
        if (tcur - tlast < 1000000/MAX_FPS)
            continue;
        tlast = tcur;

        [engine render];
    }
}
