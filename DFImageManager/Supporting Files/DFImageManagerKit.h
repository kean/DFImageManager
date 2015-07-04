//
//  DFImageManagerFramework.h
//  DFImageManagerFramework
//
//  Created by Alexander Grebenyuk on 1/18/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for DFImageManagerFramework.
FOUNDATION_EXPORT double DFImageManagerFrameworkVersionNumber;

//! Project version string for DFImageManagerFramework.
FOUNDATION_EXPORT const unsigned char DFImageManagerFrameworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DFImageManagerKit/PublicHeader.h>

#import <DFImageManagerKit/DFImageManagerDefines.h>

#import <DFImageManagerKit/DFImageManaging.h>
#import <DFImageManagerKit/DFImageFetching.h>
#import <DFImageManagerKit/DFImageCaching.h>
#import <DFImageManagerKit/DFImageProcessing.h>

#import <DFImageManagerKit/DFImageManager.h>
#import <DFImageManagerKit/DFImageManagerConfiguration.h>

// Support
#import <DFImageManagerKit/DFImageRequest.h>
#import <DFImageManagerKit/DFImageTask.h>
#import <DFImageManagerKit/DFImageRequestOptions.h>
#import <DFImageManagerKit/DFImageResponse.h>

// Caching (memory cache)
#import <DFImageManagerKit/DFImageCache.h>
#import <DFImageManagerKit/DFCachedImageResponse.h>
#import <DFImageManagerKit/NSCache+DFImageManager.h>

// Processing
#import <DFImageManagerKit/DFImageProcessor.h>

// Utilities
#import <DFImageManagerKit/DFCompositeImageManager.h>
#import <DFImageManagerKit/DFProxyImageManager.h>
#import <DFImageManagerKit/DFNetworkReachability.h>
#import <DFImageManagerKit/DFImageFetchTask.h>

// Subspec 'UI'
#import <DFImageManagerKit/DFImageManagerKit+UI.h>

// Subspec 'NSURLSession'
#import <DFImageManagerKit/DFImageManagerKit+NSURLSession.h>

// Subspec 'PhotosKit'
#import <DFImageManagerKit/DFImageManagerKit+PhotosKit.h>

// Subspec 'AssetsLibrary'
#import <DFImageManagerKit/DFImageManagerKit+AssetsLibrary.h>
