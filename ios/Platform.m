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

#import <Foundation/Foundation.h>
#import "Platform.h"

#import <mach/mach_time.h>

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
    mach_timebase_info_data_t tb;
    mach_timebase_info(&tb);
    return (uint64_t)((double)mach_absolute_time() * tb.numer / (tb.denom * 1000));
}

- (NSData*) loadResource:(NSString*)name withAppContext:(void*)context {
    NSArray *parts = [name componentsSeparatedByString:@"."];
    NSString *extPart = [parts lastObject];
    NSString *namePart = [[parts subarrayWithRange:NSMakeRange(0, [parts count] - 1)] componentsJoinedByString:@"."];
    NSString *pathname = [[NSBundle mainBundle] pathForResource:namePart ofType:extPart];
    return [NSData dataWithContentsOfFile:pathname];
}

@end
