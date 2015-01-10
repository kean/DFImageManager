# DFImageManager
DFImageManager is a modern framework for managing (fetching, caching, decompressing, preheating and more) images from various sources.

### Supported assets and assets identifiers
- NSURL with schemes http:, https:, ftp:, file:
- PHAsset
- PHAsset local identifier
- ALAsset
- NSURL with scheme assets-library:

## Features
- Completely asynchronous and thread safe. Performance-critical subsystems run entirely on the background threads
- Image decompression and resizing which results in a great performance, lack of missaligned images and low memory footprint
- Memory caching that carefully manages system resources to keep as many images as possible while preventing memory warnings
- Automatic preheating of images that are close to the viewport

## Getting Started
- [Download DFImageManager](https://github.com/kean/DFImageManager/releases) and play with [demo project](https://github.com/kean/DFImageManager/tree/master/DFImageManagerSample) 

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
