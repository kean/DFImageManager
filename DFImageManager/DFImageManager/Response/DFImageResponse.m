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

#import "DFImageResponse.h"


@interface DFImageResponse ()

@property (nonatomic) UIImage *image;
@property (nonatomic) NSError *error;
@property (nonatomic) DFImageSource source;
@property (nonatomic) NSData *data;
@property (nonatomic) NSDictionary *userInfo;

@end

@implementation DFImageResponse

- (instancetype)initWithImage:(UIImage *)image error:(NSError *)error source:(DFImageSource)source {
   if (self = [super init]) {
      _image = image;
      _error = error;
      _source = source;
   }
   return self;
}

- (instancetype)initWithResponse:(DFImageResponse *)response {
   if (self = [super init]) {
      _image = response.image;
      _error = response.error;
      _source = response.source;
      _data = response.data;
      _userInfo = response.userInfo;
   }
   return response;
}

- (id)copyWithZone:(NSZone *)zone {
   return [[DFImageResponse alloc] initWithResponse:self];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
   return [[DFMutableImageResponse alloc] initWithResponse:self];
}

+ (instancetype)emptyResponse {
   return [[DFImageResponse alloc] initWithImage:nil error:nil source:0];
}

@end


@implementation DFMutableImageResponse

@end
