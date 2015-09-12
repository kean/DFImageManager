Pod::Spec.new do |s|
    s.name         = "DFImageManager"
    s.version      = "0.7.2"
    s.summary      = "Advanced iOS framework for loading images. Zero config, yet immense customization and flexibility."
    s.homepage     = "https://github.com/kean/DFImageManager"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author             = "Alexander Grebenyuk"
    s.social_media_url   = "https://twitter.com/a_grebenyuk"
    s.platform     = :ios
    s.ios.deployment_target = "7.0"   
    s.watchos.deployment_target = "2.0"
    s.source       = { :git => "https://github.com/kean/DFImageManager.git", :tag => s.version.to_s }
    s.requires_arc = true
    s.default_subspecs = "Core", "UI", "NSURLSession", "PhotosKit"

    s.subspec "Core" do |ss|
        ss.source_files  = "Pod/Source/Core/**/*.{h,m}"
        ss.private_header_files = "Pod/Source/Core/Private/*.h"
    end

    s.subspec "UI" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.ios.source_files = "Pod/Source/UI/**/*.{h,m}"
    end

    s.subspec "NSURLSession" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.source_files = "Pod/Source/NSURLSession/**/*.{h,m}"
    end

    s.subspec "AFNetworking" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.dependency "AFNetworking/NSURLSession", "~> 2.0"
        ss.source_files = "Pod/Source/AFNetworking/**/*.{h,m}"
    end

    s.subspec "PhotosKit" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.source_files = "Pod/Source/PhotosKit/**/*.{h,m}"
    end

    s.subspec "GIF" do |ss|
        ss.dependency "FLAnimatedImage", "~> 1.0"
        ss.source_files = "Pod/Source/GIF/**/*.{h,m}"
    end

    s.subspec "WebP" do |ss|
        ss.dependency "libwebp"
        ss.source_files = "Pod/Source/WebP/**/*.{h,m}"
    end
end
