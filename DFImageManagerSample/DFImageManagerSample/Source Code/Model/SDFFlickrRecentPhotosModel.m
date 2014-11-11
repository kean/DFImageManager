// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "SDFFlickrRecentPhotosModel.h"
#import "SDFFlickrPhoto.h"


@implementation SDFFlickrRecentPhotosModel {
    NSUInteger _page;
    BOOL _isLoading;
}

- (instancetype)init {
    if (self = [super init]) {
        _page = 1;
    }
    return self;
}

- (void)load {
    if (!_isLoading) {
        _isLoading = YES;
        SDFFlickrRecentPhotosModel *__weak weakSelf = self;
        [self _loadFlickrPhotosForPage:_page completion:^(NSArray *photos) {
            [weakSelf _didLoadPhotos:photos];
        }];
    }
}

- (void)_didLoadPhotos:(NSArray *)photos {
    _isLoading = NO;
    _page++;
    [self.delegate flickrRecentPhotosModel:self didLoadPhotos:photos forPage:(_page - 1)];
}

- (void)_loadFlickrPhotosForPage:(NSUInteger)page completion:(void (^)(NSArray *photos))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?api_key=a292d5f86afcbab8b0b8161ecee51184&format=json&method=flickr.photos.getRecent&nojsoncallback=1&page=%lu", (unsigned long)page];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    SDFFlickrRecentPhotosModel *__weak weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSMutableArray *photos = [NSMutableArray new];
                NSError *parseError;
                id JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                if (!parseError) {
                    NSArray *responsePhotos = [JSON valueForKeyPath:@"photos.photo"];
                    for (id photoJSON in responsePhotos) {
                        SDFFlickrPhoto *photo = [[SDFFlickrPhoto alloc] initWithJSON:photoJSON];
                        [photos addObject:photo];
                    }
                    if (completion) {
                        completion(photos);
                    }
                }
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf _loadFlickrPhotosForPage:page completion:completion];
                });
            }
        });
    }];
}

@end
