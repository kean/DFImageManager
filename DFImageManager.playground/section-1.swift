// Playground - noun: a place where people can play

import UIKit
import DFImageManagerKit
import XCPlayground

var str = "Hello, playground"

let manager = DFImageManager.sharedManager()

let imageURL = NSURL(string: "https://raw.githubusercontent.com/kean/DFImageManager/master/DFImageManager/Tests/Resources/Image.jpg")
manager.requestImageForAsset(imageURL, targetSize: DFImageManagerMaximumSize, contentMode: DFImageContentMode.AspectFit, options: nil) { (image: UIImage!, [NSObject : AnyObject]!) -> Void in
    var fetchedImage = image
}

manager.requestImageForAsset(imageURL, targetSize: CGSize(width: 100, height: 100), contentMode: DFImageContentMode.AspectFit, options: nil) { (image: UIImage!, [NSObject : AnyObject]!) -> Void in
    var fetchedImage = image
}

XCPSetExecutionShouldContinueIndefinitely()
