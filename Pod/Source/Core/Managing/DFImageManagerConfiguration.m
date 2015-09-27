// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageDecoder.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageManagerDefines.h"

@implementation DFImageManagerConfiguration

- (instancetype)init {
    if (self = [super init]) {
        _decoder = [DFImageDecoder new];
        _processingQueue = [NSOperationQueue new];
        _processingQueue.maxConcurrentOperationCount = 2;
        _maximumConcurrentPreheatingRequests = 2;
        _progressiveImageDecodingThreshold = 0.15f;
    }
    return self;
}

+ (instancetype)configurationWithFetcher:(id<DFImageFetching>)fetcher processor:(id<DFImageProcessing>)processor cache:(id<DFImageCaching>)cache {
    DFImageManagerConfiguration *conf = [[self class] new];
    conf.fetcher = fetcher;
    conf.processor = processor;
    conf.cache = cache;
    return conf;
}

- (id)copyWithZone:(NSZone *)zone {
    DFImageManagerConfiguration *copy = [DFImageManagerConfiguration new];
    copy.fetcher = self.fetcher;
    copy.decoder = self.decoder;
    copy.cache = self.cache;
    copy.processor = self.processor;
    copy.processingQueue = self.processingQueue;
    copy.maximumConcurrentPreheatingRequests = self.maximumConcurrentPreheatingRequests;
    copy.progressiveImageDecodingThreshold = self.progressiveImageDecodingThreshold;
    return copy;
}

@end


@implementation DFImageManagerConfiguration (DFGlobalConfiguration)

static BOOL _allowsProgressiveImage = NO;

+ (void)setAllowsProgressiveImage:(BOOL)allowsProgressiveImage {
    _allowsProgressiveImage = allowsProgressiveImage;
}

+ (BOOL)allowsProgressiveImage {
    return _allowsProgressiveImage;
}

@end
