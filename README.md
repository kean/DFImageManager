<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/9706439/4d3fd63c-54ed-11e5-91ec-a52c768b67fe.png" width="70%"/>

<p align="center">
<a href="https://cocoapods.org"><img src="https://img.shields.io/cocoapods/v/DFImageManager.svg"></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
</p>

Advanced framework for loading, caching, processing, displaying and preheating images.

**Disclaimer:** It's deprecated in favor of [Nuke](https://github.com/kean/Nuke)

## <a name="h_features"></a>Features

- Zero config
- Works great with both Objective-C and Swift
- Performant, asynchronous, thread safe

##### Loading
- Uses [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) with [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2) support
- Optional [AFNetworking](#installation) integration, combine the power of both frameworks!
- Uses a single fetch operation for equivalent requests
- [Intelligent preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images close to the viewport

##### Caching
- Doesn't reinvent caching, relies on [HTTP cache](https://tools.ietf.org/html/rfc7234) and its implementation in [Foundation](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html)
- Caching is completely transparent to the client
- Two cache layers, including [top level memory cache](https://github.com/kean/DFImageManager/wiki/Image-Caching-Guide) for decompressed images

##### Processing
- Optional [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) integration
- Optional [WebP](https://developers.google.com/speed/webp/) integration
- Progressive image decoding including progressive JPEG
- Background image decompression and scaling in a single step
- Resize and crop loaded images to [fit displayed size](https://developer.apple.com/library/ios/qa/qa1708/_index.html), add rounded corners or circle

##### Advanced
- Customize different parts of the framework using dependency injection
- Create and [compose image managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager) into a tree of responsibility

## <a name="h_getting_started"></a>Getting Started
- Take a look at comprehensive [demo](https://github.com/kean/DFImageManager/tree/master/Demo) using `pod try DFImageManager` command
- Check out complete [documentation](http://cocoadocs.org/docsets/DFImageManager) and [Wiki](https://github.com/kean/DFImageManager/wiki)
- [Install](#installation), `@import DFImageManager` and enjoy!

## <a name="h_usage"></a>Usage

#### Zero Config

```objective-c
[[DFImageManager imageTaskForResource:<#imageURL#> completion:^(UIImage *image, NSError *error, DFImageResponse *response, DFImageTask *task){
    // Use loaded image
}] resume];
```

#### Adding Request Options

```objective-c
DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new]; // builder
options.priority = DFImageRequestPriorityHigh;
options.allowsClipping = YES;

DFImageRequest *request = [DFImageRequest requestWithResource:<#imageURL#> targetSize:CGSizeMake(100, 100) contentMode:DFImageContentModeAspectFill options:options.options];

[[DFImageManager imageTaskForRequest:request completion:^(UIImage *image, NSError *error, DFImageResponse *response, DFImageTask *imageTask) {
    // Image is resized and clipped to fill 100x100px square
    if (response.isFastResponse) {
        // Image was returned synchronously from the memory cache
    }
}] resume];
```

#### Using Image Task

```objective-c
DFImageTask *task = [DFImageManager imageTaskForResource:<#imageURL#> completion:nil];
NSProgress *progress = task.progress;
task.priority = DFImageRequestPriorityHigh; // Change priority of executing task
[task cancel];
```

#### Using UI Components
Use methods from `UIImageView` category for simple cases:
```objective-c
UIImageView *imageView = ...;
[imageView df_setImageWithResource:<#imageURL#>];
```

Use `DFImageView` for more advanced features:
```objective-c
DFImageView *imageView = ...;
imageView.allowsAnimations = YES; // Animates images when the response wasn't fast enough
imageView.managesRequestPriorities = YES; // Automatically changes current request priority when image view gets added/removed from the window

[imageView prepareForReuse];
[imageView setImageWithResource:<#imageURL#>];
```

#### UICollectionView

```objective-c
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = <#cell#>
    DFImageView *imageView = (id)[cell viewWithTag:15];
    if (!imageView) {
        imageView = [[DFImageView alloc] initWithFrame:cell.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.tag = 15;
        [cell addSubview:imageView];
    }
    [imageView prepareForReuse];
    [imageView setImageWithResource:<#image_url#>];
    return cell;
}
```

Cancel image task as soon as the cell goes offscreen (optional):

```objective-c
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [((DFImageView *)[cell viewWithTag:15]) prepareForReuse];
}
```

#### Preheating Images

```objective-c
NSArray<DFImageRequest *> *requestsForAddedItems = <#requests#>;
[DFImageManager startPreheatingImagesForRequests:requestsForAddedItems];

NSArray<DFImageRequest *> *requestsForRemovedItems = <#requests#>;
[DFImageManager stopPreheatingImagesForRequests:requestsForRemovedItems];
```

#### Progressive Image Decoding

```objective-c
// Enable progressive image decoding
[DFImageManagerConfiguration setAllowsProgressiveImage:YES];

// Create image request that allows progressive image
DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
options.allowsProgressiveImage = YES;
DFImageRequest *request = <#request#>;

DFImageTask *task = <#task#>;
task.progressiveImageHandler = ^(UIImage *__nonnull image){
    imageView.image = image;
};
[task resume];
```

#### Customizing Image Manager

```objective-c
id<DFImageFetching> fetcher = <#fetcher#>;
id<DFImageDecoding> decoder = <#decoder#>;
id<DFImageProcessing> processor = <#processor#>;
id<DFImageCaching> cache = <#cache#>;

DFImageManagerConfiguration *configuration = [[DFImageManagerConfiguration alloc] initWithFetcher:fetcher];
configuration.decoder = decoder;
configuration.processor = processor;
configuration.cache = cache;

[DFImageManager setSharedManager:[[DFImageManager alloc] initWithConfiguration:configuration]];
```

#### Composing Image Managers
The `DFCompositeImageManager` constructs a [tree of responsibility](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager) from image managers and dynamically dispatch requests between them. Each manager should conform to `DFImageManaging` protocol. The `DFCompositeImageManager` also conforms to `DFImageManaging` protocol so that individual managers and compositions can be treated uniformly.

```objective-c
id<DFImageManaging> manager1 = <#manager#>
id<DFImageManaging> manager2 = <#manager#>
id<DFImageManaging> composite = [[DFCompositeImageManager alloc] initWithImageManagers:@[manager1, manager2]];
```

## <a name="h_design"></a>Design

<img src="https://cloud.githubusercontent.com/assets/1567433/9706417/0352d3bc-54ed-11e5-94ff-cb8691800f78.png" width="66%"/>

|Protocol|Description|
|--------|-----------|
|`DFImageManaging`|A high-level API for loading images|
|`DFImageFetching`|Performs fetching of image data (`NSData`)|
|`DFImageDecoding`|Converts `NSData` to `UIImage` objects|
|`DFImageProcessing`|Processes decoded images|
|`DFImageCaching`|Stores processed images into memory cache|

## Installation<a name="installation"></a>

### [CocoaPods](http://cocoapods.org)

To install DFImageManager add a dependency in your Podfile:
```ruby
pod 'DFImageManager'
```

By default it will install these subspecs:
- `DFImageManager/Core` - DFImageManager core classes
- `DFImageManager/UI` - UI components

There are four more optional subspecs:
- `DFImageManager/AFNetworking` - replaces networking stack with [AFNetworking](https://github.com/AFNetworking/AFNetworking)
- `DFImageManager/GIF` - GIF support with a [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) dependency
- `DFImageManager/WebP` - WebP support with a [libwebp](https://cocoapods.org/pods/libwebp) dependency
- `DFImageManager/PhotosKit` - Photos Framework support

To install optional subspecs include them in your Podfile:
```ruby
pod 'DFImageManager'
pod 'DFImageManager/AFNetworking'
pod 'DFImageManager/GIF'
pod 'DFImageManager/WebP'
pod 'DFImageManager/PhotosKit'
```

### [Carthage](https://github.com/Carthage/Carthage)

 DFImageManager has a limited Carthage support that doesn't feature [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) and [AFNetworking](https://github.com/AFNetworking/AFNetworking) integration. To install DFImageManager add a dependency to your Cartfile:
```
github "kean/DFImageManager"
```

## <a name="h_requirements"></a>Requirements
- iOS 8.0+ / watchOS 2
- Xcode 7.0+

## <a name="h_supported_image_formats"></a>Supported Image Formats
- Image formats supported by `UIImage` (JPEG, PNG, BMP, [and more](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImage_Class/))
- GIF (`GIF` subspec)
- WebP (`WebP` subspec)

## <a name="h_contribution"></a>Contribution

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager). (Tag 'dfimagemanager')
- If you **found a bug**, and can provide steps to reproduce it, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, branch of the `develop` branch and submit a pull request.

## Contacts

<a href="https://github.com/kean">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521218/9c7e2502-c378-11e4-9431-c7255cf39577.png" height="44" hspace="2"/>
</a>
<a href="https://twitter.com/a_grebenyuk">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521243/fb085da4-c378-11e4-973e-1eeeac4b5ba5.png" height="44" hspace="2"/>
</a>
<a href="https://www.linkedin.com/pub/alexander-grebenyuk/83/b43/3a0">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521256/20247bc2-c379-11e4-8e9e-417123debb8c.png" height="44" hspace="2"/>
</a>

## License

DFImageManager is available under the MIT license. See the LICENSE file for more info.
