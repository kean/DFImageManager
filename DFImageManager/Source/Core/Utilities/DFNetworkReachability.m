// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFNetworkReachability.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

NSString *DFNetworkReachabilityDidChangeNotification = @"DFNetworkReachabilityDidChangeNotification";

@interface DFNetworkReachability ()

@property (nonatomic) SCNetworkReachabilityFlags flags;

@end

static void _DFReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    NSCAssert(info != NULL, @"info was NULL in _DFReachabilityCallback");
    NSCAssert([(__bridge NSObject *)info isKindOfClass: [DFNetworkReachability class]], @"invalid info _DFReachabilityCallback");
    DFNetworkReachability *reachability = (__bridge DFNetworkReachability *)info;
    reachability.flags = flags;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName: DFNetworkReachabilityDidChangeNotification object:reachability];
    });
}

@implementation DFNetworkReachability {
    SCNetworkReachabilityRef _reachabilityRef;
}

- (void)dealloc {
    if (_reachabilityRef != NULL) {
        [self _stopNotifier];
        CFRelease(_reachabilityRef);
    }
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachabilityRef {
    if (self = [super init]) {
        _reachabilityRef = reachabilityRef;
        if (_reachabilityRef != NULL) {
            [self _determineCurrentReachabilityFlags];
            [self _startNotifier];
        }
    }
    return self;
}

+ (instancetype)shared {
    static DFNetworkReachability *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self _reachabilityForInternetConnection];
        [shared _startNotifier];
    });
    return shared;
}

+ (instancetype)_reachabilityForInternetConnection {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self _reachabilityWithAddress:&zeroAddress];
}

+ (instancetype)_reachabilityWithAddress:(const struct sockaddr_in *)hostAddress; {
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);
    return [[DFNetworkReachability alloc] initWithReachability:reachabilityRef];
}

- (void)_determineCurrentReachabilityFlags {
    DFNetworkReachability *__weak weakSelf = self;
    // Get flags asynchously just in case.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.flags = flags;
            });
        }
    });
}

- (BOOL)isReachable {
    return (self.flags & kSCNetworkReachabilityFlagsReachable) != 0;
}

- (void)_startNotifier {
    SCNetworkReachabilityContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL};
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, _DFReachabilityCallback, &context)) {
        SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void)_stopNotifier {
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

@end
