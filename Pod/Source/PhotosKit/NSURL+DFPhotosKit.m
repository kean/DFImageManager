// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "NSURL+DFPhotosKit.h"
#import <Photos/Photos.h>

@implementation NSURL (DFPhotosKit)

+ (NSURL *)df_assetURLWithAssetLocalIdentifier:(NSString *)localIdentifier {
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = DFPhotosKitURLScheme;
    components.host = @"photos";
    components.path = [NSString stringWithFormat:@"/asset"];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"local_identifier" value:localIdentifier]];
    return components.URL;
}

+ (NSURL *)df_assetURLWithAsset:(PHAsset *)asset {
    return [self df_assetURLWithAssetLocalIdentifier:asset.localIdentifier];
}

- (NSString *)df_assetLocalIdentifier {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    NSURLQueryItem *queryItem = [components.queryItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name=%@", @"local_identifier"]].firstObject;
    return queryItem.value;
}

@end
