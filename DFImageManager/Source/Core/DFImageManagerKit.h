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

#import "DFImageManagerDefines.h"

#import "DFImageManaging.h"
#import "DFImageFetching.h"
#import "DFImageCaching.h"
#import "DFImageProcessing.h"

#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"

// Support
#import "DFImageRequest.h"
#import "DFImageTask.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"

// Caching (memory cache)
#import "DFImageCache.h"
#import "DFCachedImageResponse.h"
#import "NSCache+DFImageManager.h"

// Processing
#import "DFImageProcessor.h"

// Utilities
#import "DFCompositeImageManager.h"
#import "DFProxyImageManager.h"
#import "DFNetworkReachability.h"
#import "DFCompositeImageTask.h"

// Subspec 'UI'
#if __has_include("DFImageManagerKit+UI.h")
#import "DFImageManagerKit+UI.h"
#endif

// Subspec 'NSURLSession'
#if __has_include("DFImageManagerKit+NSURLSession.h")
#import "DFImageManagerKit+NSURLSession.h"
#endif

// Subspec 'AFNetworking'
#if DF_IMAGE_MANAGER_AFNETWORKING_AVAILABLE
#import "DFImageManagerKit+AFNetworking.h"
#endif

// Subspec 'PhotosKit'
#if __has_include("DFImageManagerKit+PhotosKit.h")
#import "DFImageManagerKit+PhotosKit.h"
#endif

// Subspec 'AssetsLibrary'
#if __has_include("DFImageManagerKit+AssetsLibrary.h")
#import "DFImageManagerKit+AssetsLibrary.h"
#endif

// Subspec 'GIF'
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

// Subspec 'WebP'
#if DF_IMAGE_MANAGER_WEBP_AVAILABLE
#import "DFImageManagerKit+WebP.h"
#endif
