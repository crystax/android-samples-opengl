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

#import "Platform.h"

#import <time.h>
#import <errno.h>
#import <string.h>
#import <stdlib.h>

#import <android/native_activity.h>

static Platform *instance = nil;

@implementation Platform

+ (instancetype) sharedInstance {
    @synchronized(self.class) {
        if (!instance)
            instance = [Platform new];
    }
    return instance;
}

- (uint64_t) monotime {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) < 0) {
        NSLog(@"FATAL: clock_gettime() failed: %s", strerror(errno));
        abort();
    }

    return (uint64_t)ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
}

- (NSData*) loadResource:(NSString*)name withAppContext:(void*)context {
    ANativeActivity *activity = (ANativeActivity*)context;

    AAsset* assetFile = AAssetManager_open(activity->assetManager, [name UTF8String], AASSET_MODE_BUFFER);
    if (!assetFile) {
        NSLog(@"Can't find asset '%@'", name);
        return nil;
    }

    @try {
        uint8_t *data = (uint8_t*)AAsset_getBuffer(assetFile);
        int32_t size = AAsset_getLength(assetFile);
        if (!data) {
            NSLog(@"Can't load asset '%@'", name);
            return nil;
        }

        return [NSData dataWithBytes:data length:size];
    }
    @finally {
        AAsset_close(assetFile);
    }
}

@end
