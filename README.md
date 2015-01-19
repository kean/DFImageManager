# DFImageManager
DFImageManager is a modern framework for managing fetching, caching, decompressing, preheating of images from various sources.

### Supported assets and asset identifiers
- NSURL with schemes http:, https:, ftp:, file:
- PHAsset and NSURL with scheme com.github.kean.photos-kit:
- ALAsset and NSURL with scheme assets-library:

## Features
- Uses latest advancements in [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) including [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/).
- Instead of reinventing a caching methodology it relies on HTTP cache as defined in [HTTP specification](https://tools.ietf.org/html/rfc7234) and caching implementation provided by [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html).
- Has a separate in-memory cache layer that stores decompressed (and/or resized and processed in other ways) images. Image resizing results in a lack of misaligned images and lower memory footprint. Image processing is optional and fully customizable.
- [Automatic preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images that are close to the viewport.
- Groups the same requests and never executes them twice. This is true for both fetching and processing. For example, the user creates three requests for the same URL, two of the requests want the image to be resized to the same target size while the other one wants the original image. `DFImageManager` will fetch the original image once, then it will resize it once, no extra work will be done. `DFImageManager` provides a fine grained control over which requests should be considered equivalent (both in terms of fetching and processing).
- Completely asynchronous and thread safe. Performance-critical subsystems run entirely on the background threads.
- High quality code base that successfully manages complexity and follows best design principles and patterns.

## Getting Started
- Download the [latest DFImageManager version](https://github.com/kean/DFImageManager/releases)
- Take a look at the comprehensive [demo projects](https://github.com/kean/DFImageManager/tree/master/DFImageManagerSample)
- Play with `DFImageManager` API in a Swift DFImageManager.playground
- Read guides on [Wiki](https://github.com/kean/DFImageManager/wiki)

## Requirements
iOS 7.0+

## Installation with [CocoaPods](http://cocoapods.org)

CocoaPods is the dependency manager for Cocoa projects, which automates the process of integrating thrid-party frameworks like DFImageManager. If you are not familiar with CocoaPods the best place to start would be [official CocoaPods guides](http://guides.cocoapods.org).
```ruby
# Podfile example
platform :ios, '7.0'
pod 'DFImageManager'
```

## Contacts
[Alexander Grebenyuk](https://github.com/kean)

## License
DFCache is available under the MIT license. See the LICENSE file for more info.
