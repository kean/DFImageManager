# DFImageManager
DFImageManager is a modern framework for managing fetching, caching, decompressing, preheating of images from various sources.

### Supported assets and asset identifiers
- NSURL with schemes http:, https:, ftp:, file:
- PHAsset and NSURL with scheme com.github.kean.photos-kit:
- ALAsset and NSURL with scheme assets-library:

## Features
- Completely asynchronous and thread safe. Performance-critical subsystems run entirely on the background threads.
- Uses latest advancements in [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) including [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/).
- Instead of reinventing a caching methodology it relies on HTTP cache as defined in [HTTP specification](https://tools.ietf.org/html/rfc7234) and caching implementation provided by [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) ([NSURLCache](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLCache_Class/index.html)).
- Has a separate in-memory cache layer that stores decompressed (optionally resized and adjusted in other ways) images ready for display. Optional image resizing results in a lack of missaligned images and lower memory footprint.
- [Automatic preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images that are close to the viewport.

## Getting Started
- [Download DFImageManager](https://github.com/kean/DFImageManager/releases) and play with [demo project](https://github.com/kean/DFImageManager/tree/master/DFImageManagerSample)
- Read guides on [Wiki](https://github.com/kean/DFImageManager/wiki)

## Requirements
iOS 7

## Installation with [Cocoapods](http://cocoapods.org)
```ruby
# Podfile example
platform :ios, '7.0'
pod 'DFImageManager'
```

## Contacts
[Alexander Grebenyuk](https://github.com/kean)

## License
DFCache is available under the MIT license. See the LICENSE file for more info.
