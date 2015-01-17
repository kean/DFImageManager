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

#import "DFImageAssetProtocol.h"
#import "DFImageManager.h"
#import <Foundation/Foundation.h>


/*! Uses existing DFImageManager infrastructure to provide clients with the ability to easily reuse and cancel processing operations. Processing manager is initialized with a <DFImageProcessor> and an operation queue which are then wrapped into a class that implements <DFImageFetcher> protocol.
 */
@interface DFProcessingImageManager : DFImageManager

- (instancetype)initWithProcessor:(id<DFImageProcessor>)processor queue:(NSOperationQueue *)queue;

@end


@interface DFProcessingInput : NSObject <DFImageAsset>

@property (nonatomic, readonly) UIImage *image;

- (instancetype)initWithImage:(UIImage *)image identifier:(NSString *)identifier;

@end
