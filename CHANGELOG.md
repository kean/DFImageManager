 [Changelog](https://github.com/kean/DFImageManager/releases) for all versions

# DFImageManager 0.7.1

`DFImageManager 0.7.1` focuses on stability and performance. The main changes were made to image processing. Images are now decompressed and scaled in a single step (x2-4 times faster depending on scale, significantly reduces memory usage) which allow DFImageManager to scales large images (~6000x4000 px) and prepares them for display with ease.

## Changes

### Major

- #64 Image decompression and scaling are now made in a single step (x2-4 times faster depending on scale, significantly reduces memory usage)

### Minor 

- #70 Always draw decompressed images using kCGImageAlphaPremultipliedFirst and CGColorSpaceCreateDeviceRGB
- #67 Refactor task queue in DFURLImageFetcher; Delay only execution of session tasks, not cancellation
- #66 DFPhotosKitImageFetcher remove obsolete targetSize and contentMode checks in isRequestCacheEquivalent:toRequest method
- #65 Remove excessive initWithAnimatedGIFData: method from DFAnimatedImage; make animatedImage property nonnull
- #63 Remove unused methods from UIImage+DFImageUtilities
- #60 Make DFImageManager/Core subspec smaller by moving non-core classes to DFImageManager/Extensions subspec.
- Remove excessive DFImageViewDelegate
- Remove excessive imageTargetSize, imageContentMode and imageRequestOptions properties from DFImageView
- Remove excessive -[DFURLImageFetcherDelegate URLImageFetcher:didEncounterError:] method

### Bugfix

- #71 BUGFIX: DFImageManagerImageLoader sometimes fails to cancel fetch operations
- #69 BUGFIX: Fix -[DFImageManager invalidateAndCancel]
- #68 BUGFIX: Add optional -[DFImageFetching invalidate] method that would allow DFURLImageFetcher and DFAFImageFetcher to invalidate NSURLSession and release delegate
- #62 BUGFIX: Fix GIF cost calculation in DFImageCache
- BUGFIX: Fix DFImageView priority management


# DFImageManager 0.7.0

`DFImageManager 0.7.0` brings progressive image decoding support, and puts everything in its right place. It adds a separate stage for image decoding (see new `DFImageDecoding` protocol), and narrows role of the `DFImageFetching` protocol which is now only responsible for fetching image data (NSData).

## Changes

### Major

- #46 Add a separate stage for image decoding. Add multiple ways to configure and extend image decoding: add DFImageDecoding protocol, DFImageDecoder class; add decoder to DFImageManagerConfiguration; add dependency injector to set shared decoder.
- #41 Add GIF support for PHAsset. Also includes major changes in DFImageFetching protocol, which is now only responsible for fetching image data (NSData).
- #28 Add progressive image decoding, including progressive JPEG support.
- Remove ALAssetsLibrary support due to the changes to the DFImageFetching protocol that now returns NSData instead of UIImage. It's easy to add you own application-specific ALAssetsLibrary support by either implementing DFImageFetching protocol and fetching NSData (and letting DFImageManager class do all the decoding, processing, caching and preheating), or by implementing DFImageManaging protocol itself.

### Minor

- #56 Xcode 7 compatibility
- #54 Add shouldDecompressImages property to DFImageDecoder. Default value is YES.
- #53 Add Carthage support
- #52 Add defaultOptions class method to DFMutableImageRequestOptions which allows user to modify request options on per-application level
- #51 DFImageProcessor makes a decision of weather it should process GIF images, not DFImageManager
- #50 Add removeAllCachedImages to DFImageManaging protocol; Add optional removeAllCachedImages to DFImageFetching protocol
- #49 Add shouldProcessImage:forRequest: method to DFImageProcessing protocol that would allow DFImageManager to skip processing step entirely
- #47 Better signature checks to identify image formats; Add WebP signature check
- Refactor DFImageManagerImageLoader (private class that was introduced in the previous version)
- Improve DFImageView performance (use DFImageTask directly)
- Remove DFNetworkReachability and auto retry from DFImageView
- Add "Design" section in readme file, update examples


# DFImageManager 0.6.0

`DFImageManager 0.6.0` focuses on consistency and performance. It features some minor improvements in the API and some major improvements in the implementation. The main changes were made to the DFImageManager class that was made much more approachable.

## Changes

### Major

- #38 DFImageRequest and DFImageRequestOptions are now immutable, options are created using builder
- #37 Improve DFImageTaskCompletion completion block. Remove dictionary with DFImageInfo* keys; error (NSError *) is now a separate argument; add response (DFImageResponse) and completedTask (DFImageTask) parameters. It's now easier to discover all options.
- #34 DFImageManager implementation is now much more approachable, and also more robust and performant (request execution management is moved from DFImageManager to a separate private class).
- #32 DFImageTask now changes state synchronously on the callers thread (when you resume or cancel task). As a "side effect" DFImageManager invalidation is now thread safe.
- #19 NSProgress is now used instead of blocks. Includes support for implicit progress composition, cancellation using progress objects, and more.

### Minor

- #39 Improve DFCompositeImageManager dispatch logic for preheating requests
- #36 Multiple preheating performance improvements. DFImageManager now automatically removes obsolete preheating tasks without even resuming them.
- #35 UI classes now accept nullable resources and requests (more convenient)
- #33 BUGFIX: Remove setNeedsUpdateConstrains call from DFImageView
- #30 UIImageView df_setImage: family of methods now return DFImageTask
- Make nullability annotations explicit; fixe nullability annotations in couple of places
- Other minor improvements that include consistent dot-syntax usage, making some properties copying and more
- Remove deprecated methods


# DFImageManager 0.5.0

`DFImageManager 0.5.0` brings [WebP](https://developers.google.com/speed/webp/) support, introduces some great new APIs, and features redesigned `DFCompositeImageTask`.

## Changes

- #14 WebP support
- #22 Rename `DFImageRequestID` to `DFImageTask`, add new public interfaces (`state`, `request`, `error` and more)
- #24 `DFImageManager` guarantees that the error is always created when the task fails
- #25 Add `-resume` method to `DFImageTask`, tasks should not start running automatically
- #26 Completely redesigned `DFCompositeImageTask`, simple interface, fully covered by unit tests
- #27 Add `- (void)getImageTasksWithCompletion:(void (^)(NSArray *tasks, NSArray *preheatingTasks))completion;` method to `DFImageManaging` protocol
- Minor performance improvements
