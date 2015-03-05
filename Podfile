platform :ios, "7.0"

xcodeproj "DFImageManager/DFImageManager.xcodeproj"
workspace "DFImageManager.xcworkspace"

source "https://github.com/CocoaPods/Specs.git"

link_with "DFImageManager", "DFImageManagerKit"

pod "FLAnimatedImage", "~> 1.0"

target :DFImageManagerTests, :exclusive => true do
    pod "OHHTTPStubs"
end