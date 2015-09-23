Pod::Spec.new do |s|
    s.name         = "DFImageManager"
    s.version      = "0.8.0"
    s.summary      = "Advanced framework for loading images. Zero config, yet immense customization and extensibility."
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
        ss.exclude_files = "Pod/Source/Core/DFImageManagerKit.h"
    end

    s.subspec "UI" do |ss|
        ss.ios.deployment_target = "7.0"
        ss.dependency "DFImageManager/Core"
        ss.ios.source_files = "Pod/Source/UI/**/*.{h,m}"
        ss.ios.exclude_files = "Pod/Source/UI/DFImageManagerKit+UI.h"
    end

    s.subspec "NSURLSession" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.source_files = "Pod/Source/NSURLSession/**/*.{h,m}"
        ss.exclude_files = "Pod/Source/NSURLSession/DFImageManagerKit+NSURLSession.h"
    end

    s.subspec "AFNetworking" do |ss|
        ss.ios.deployment_target = "7.0"
        ss.dependency "DFImageManager/Core"
        ss.dependency "AFNetworking/NSURLSession", "~> 2.0"
        ss.source_files = "Pod/Source/AFNetworking/**/*.{h,m}"
        ss.exclude_files = "Pod/Source/AFNetworking/DFImageManagerKit+AFNetworking.h"
    end

    s.subspec "PhotosKit" do |ss|
        ss.ios.deployment_target = "7.0"
        ss.dependency "DFImageManager/Core"
        ss.source_files = "Pod/Source/PhotosKit/**/*.{h,m}"
        ss.exclude_files = "Pod/Source/PhotosKit/DFImageManagerKit+PhotosKit.h"
    end

    s.subspec "GIF" do |ss|
        ss.ios.deployment_target = "7.0"
        ss.dependency "FLAnimatedImage", "~> 1.0"
        ss.source_files = "Pod/Source/GIF/**/*.{h,m}"
        ss.exclude_files = "Pod/Source/GIF/DFImageManagerKit+GIF.h"
    end

    s.subspec "WebP" do |ss|
        ss.ios.deployment_target = "7.0"
        ss.dependency "libwebp"
        ss.source_files = "Pod/Source/WebP/**/*.{h,m}"
        ss.exclude_files = "Pod/Source/WebP/DFImageManagerKit+WebP.h"
    end
end
