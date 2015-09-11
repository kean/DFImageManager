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

// Subspec 'Core'

#import "DFImageManagerDefines.h"

#import "DFImageManaging.h"
#import "DFImageFetching.h"
#import "DFImageFetchingOperation.h"
#import "DFImageCaching.h"
#import "DFImageProcessing.h"
#import "DFImageDecoding.h"

#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFCompositeImageManager.h"

#import "DFImageTask.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"

#import "DFImageCache.h"
#import "DFCachedImageResponse.h"
#import "NSCache+DFImageManager.h"

#import "DFImageDecoder.h"
#import "DFImageProcessor.h"
#import "UIImage+DFImageUtilities.h"


// Subspec 'Extensions'
#if __has_include("DFImageManagerKit+Extensions.h")
#import "DFImageManagerKit+Extensions.h"
#endif

// Subspec 'UI'
#if __has_include("DFImageManagerKit+UI.h")
#import "DFImageManagerKit+UI.h"
#endif

// Subspec 'NSURLSession'
#if __has_include("DFImageManagerKit+NSURLSession.h")
#import "DFImageManagerKit+NSURLSession.h"
#endif

// Subspec 'AFNetworking'
#if __has_include("DFImageManagerKit+AFNetworking.h")
#import "DFImageManagerKit+AFNetworking.h"
#endif

// Subspec 'PhotosKit'
#if __has_include("DFImageManagerKit+PhotosKit.h")
#import "DFImageManagerKit+PhotosKit.h"
#endif

// Subspec 'GIF'
#if __has_include("DFImageManagerKit+GIF.h")
#import "DFImageManagerKit+GIF.h"
#endif

// Subspec 'WebP'
#if __has_include("DFImageManagerKit+WebP.h")
#import "DFImageManagerKit+WebP.h"
#endif
