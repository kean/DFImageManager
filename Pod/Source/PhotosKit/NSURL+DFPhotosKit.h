// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

@class PHAsset;

NS_ASSUME_NONNULL_BEGIN

/*! The URL scheme used for accessing PHAsset objects.
 */
static NSString *const DFPhotosKitURLScheme = @"com.github.kean.photos-kit";

/*! The NSURL category that adds methods for manipulating URLs with "com.github.kean.photos-kit" scheme.
 */
@interface NSURL (DFPhotosKit)

/*! Returns NSURL with a given local identifier for asset.
 */
+ (nullable NSURL *)df_assetURLWithAssetLocalIdentifier:(nullable NSString *)localIdentifier NS_AVAILABLE_IOS(8_0);

/*! Returns NSURL with a local identifier for a given asset.
 */
+ (nullable NSURL *)df_assetURLWithAsset:(nullable PHAsset *)asset NS_AVAILABLE_IOS(8_0);

/*! Returns local identifier from a given URL.
 */
- (nullable NSString *)df_assetLocalIdentifier NS_AVAILABLE_IOS(8_0);

@end

NS_ASSUME_NONNULL_END
