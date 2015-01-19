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

#import "DFAssetsLibraryImageFetcher.h"
#import "DFCompositeImageManager.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageProcessor.h"
#import "DFPhotosKitImageFetcher.h"
#import "DFProxyImageManager.h"
#import "DFURLImageFetcher.h"


@implementation DFImageManager (DefaultManager)

+ (id<DFImageManagerCore>)defaultManager {
    static id<DFImageManagerCore> defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [self _createDefaultManager];
    });
    return defaultManager;
}

+ (id<DFImageManagerCore>)_createDefaultManager {
    DFImageProcessor *processor = [DFImageProcessor new];
    
    DFImageManager *URLImageManager = ({
        // Initialize NSURLCache without memory cache because DFImageManager has a higher level memory cache (see <DFImageCache>.
        NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:1024 * 1024 * 256 diskPath:@"com.github.kean.default_image_cache"];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.URLCache = cache;
        configuration.HTTPShouldUsePipelining = YES;
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        
        DFURLImageFetcher *fetcher = [[DFURLImageFetcher alloc] initWithSession:session];
        [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:processor cache:processor]];
    });
    
    DFImageManager *photosKitImageManager = ({
        DFPhotosKitImageFetcher *fetcher = [DFPhotosKitImageFetcher new];
        
        // We don't need image decompression, because PHImageManager does it for us.
        [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:nil cache:processor]];
    });
    
    DFImageManager *assetsLibraryImageManager = ({
        DFAssetsLibraryImageFetcher *fetcher = [DFAssetsLibraryImageFetcher new];
        
        // We do need both image decompression and caching.
        [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:processor cache:processor]];
    });
    
    DFCompositeImageManager *compositeImageManager = [[DFCompositeImageManager alloc] initWithImageManagers:@[ URLImageManager, photosKitImageManager, assetsLibraryImageManager ]];

    return compositeImageManager;
}

@end
