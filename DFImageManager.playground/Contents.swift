// Playground - noun: a place where people can play

import UIKit
import DFImageManagerKit
import XCPlayground
//: ## DFImageManager

let manager = DFImageManager.sharedManager()

//: Zero config image fetching. Use shared manager to request an image for the given URL. The completion block is called with a decompressed, fullsize image.
let imageURL = NSURL(string: "http://farm8.staticflickr.com/7315/16455839655_7d6deb1ebf_z_d.jpg")!
manager.requestImageForResource(imageURL) { (image: UIImage?, _) -> Void in
    var fetchedImage = image
}

//: Use DFImageRequest class to set specific request parameters like output image size (in pixels).
let request = DFImageRequest(resource: imageURL, targetSize: CGSize(width: 100, height: 100), contentMode: .AspectFill, options: nil)
manager.requestImageForRequest(request) { (image: UIImage?, _) -> Void in
    var fetchedImage = image
}

//: Image manager returns instance of DFImageTask class for each image request. Image task can be used to cancel request or change its priority and more.
let task = manager.requestImageForResource(NSURL(string: "http://farm6.staticflickr.com/5311/14244377986_c3c660ef30_k_d.jpg")!, completion: { (image, info) -> Void in
    var fetchedImage = image
    let error = info[DFImageInfoErrorKey] as! NSError
})
task?.setPriority(.High)
task?.cancel()

XCPSetExecutionShouldContinueIndefinitely()
