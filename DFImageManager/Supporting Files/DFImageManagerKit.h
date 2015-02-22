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

#import <DFImageManagerKit/DFImageCaching.h>
#import <DFImageManagerKit/DFImageFetching.h>
#import <DFImageManagerKit/DFImageManaging.h>
#import <DFImageManagerKit/DFImageProcessing.h>
#import <DFImageManagerKit/DFImageManagerValueTransforming.h>

#import <DFImageManagerKit/DFImageManager.h>
#import <DFImageManagerKit/DFImageManagerConfiguration.h>

#import <DFImageManagerKit/DFCompositeImageManager.h>
#import <DFImageManagerKit/DFProxyImageManager.h>

#import <DFImageManagerKit/DFImageRequest.h>
#import <DFImageManagerKit/DFImageRequestID.h>
#import <DFImageManagerKit/DFImageRequestOptions.h>
#import <DFImageManagerKit/DFImageResponse.h>

#import <DFImageManagerKit/DFURLImageFetcher.h>
#import <DFImageManagerKit/DFURLImageRequestOptions.h>
#import <DFImageManagerKit/DFURLSessionOperation.h>
#import <DFImageManagerKit/DFURLResponseDeserializing.h>
#import <DFImageManagerKit/DFURLImageDeserializer.h>
#import <DFImageManagerKit/DFURLHTTPImageDeserializer.h>

#import <DFImageManagerKit/DFPhotosKitImageFetcher.h>
#import <DFImageManagerKit/DFPhotosKitImageRequestOptions.h>
#import <DFImageManagerKit/NSURL+DFPhotosKit.h>
#import <DFImageManagerKit/DFPhotosKitImageFetchOperation.h>

#import <DFImageManagerKit/ALAssetsLibrary+DFImageManager.h>
#import <DFImageManagerKit/DFAssetsLibraryImageFetcher.h>
#import <DFImageManagerKit/DFAssetsLibraryImageRequestOptions.h>
#import <DFImageManagerKit/DFAssetsLibraryImageFetchOperation.h>
#import <DFImageManagerKit/DFAssetsLibraryUtilities.h>

#import <DFImageManagerKit/DFImageProcessor.h>
#import <DFImageManagerKit/DFProcessingImageFetcher.h>
#import <DFImageManagerKit/DFProcessingInput.h>

#import <DFImageManagerKit/DFImageCache.h>
#import <DFImageManagerKit/DFCachedImage.h>
#import <DFImageManagerKit/NSCache+DFImageManager.h>

// UI

#import <DFImageManagerKit/UIImageView+DFImageManager.h>
#import <DFImageManagerKit/DFImageView.h>
#import <DFImageManagerKit/DFImageContainerView.h>

// Utilities

#import <DFImageManagerKit/DFCollectionViewPreheatingController.h>
#import <DFImageManagerKit/DFCompositeImageRequest.h>
#import <DFImageManagerKit/DFOperation.h>
#import <DFImageManagerKit/DFImageUtilities.h>
#import <DFImageManagerKit/DFImageManagerBlockValueTransformer.h>
#import <DFImageManagerKit/DFNetworkReachability.h>
