// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

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
