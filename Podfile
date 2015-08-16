platform :ios, "7.0"

xcodeproj "DFImageManager/DFImageManager.xcodeproj"
workspace "DFImageManager.xcworkspace"

source "https://github.com/CocoaPods/Specs.git"

link_with "DFImageManager"

pod "AFNetworking/NSURLSession", "~> 2.0"
pod "FLAnimatedImage", "~> 1.0"
pod "libwebp"

target :DFImageManagerTests, :exclusive => true do
	pod "AFNetworking/NSURLSession", "~> 2.0"
	pod "FLAnimatedImage", "~> 1.0"
	pod "libwebp"
    pod "OHHTTPStubs"
end
