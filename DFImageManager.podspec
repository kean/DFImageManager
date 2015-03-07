Pod::Spec.new do |s|
    s.name         = "DFImageManager"
    s.version      = "0.1.0"
    s.summary      = "Modern iOS framework for fetching images from various sources. Zero config, yet immense customization and extensibility."
    s.homepage     = "https://github.com/kean/DFImageManager"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author             = { "Alexander Grebenyuk" => "grebenyuk.alexander@gmail.com" }
    s.social_media_url   = "https://twitter.com/a_grebenyuk"
    s.platform     = :ios
    s.ios.deployment_target = "7.0"
    s.source       = { :git => "https://github.com/kean/DFImageManager.git", :tag => s.version.to_s }
    s.requires_arc = true

    s.subspec "Core" do |ss|
        ss.source_files  = "DFImageManager/Source/Core/**/*.{h,m}"
    end

    s.subspec "UI" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.source_files = "DFImageManager/Source/UI/**/*.{h,m}"
    end

    s.subspec "PhotosKit" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.source_files = "DFImageManager/Source/PhotosKit/**/*.{h,m}"
    end

    s.subspec "AssetsLibrary" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.source_files = "DFImageManager/Source/AssetsLibrary/**/*.{h,m}"
    end

    s.subspec "GIF" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.dependency "FLAnimatedImage", "~> 1.0"
        ss.source_files = "DFImageManager/Source/GIF/**/*.{h,m}"
    end

end
