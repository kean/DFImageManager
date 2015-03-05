Pod::Spec.new do |s|
    s.name         = "DFImageManager"
    s.version      = "0.0.18"
    s.summary      = "Modern iOS framework for fetching images from various sources. Zero config, yet immense customization and extensibility."
    s.homepage     = "https://github.com/kean/DFImageManager"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author             = { "Alexander Grebenyuk" => "grebenyuk.alexander@gmail.com" }
    s.social_media_url   = "https://www.facebook.com/agrebenyuk"
    s.platform     = :ios
    s.ios.deployment_target = "7.0"
    s.source       = { :git => "https://github.com/kean/DFImageManager.git", :tag => s.version.to_s }
    s.requires_arc = true

    s.subspec "Core" do |ss|
        ss.source_files  = "DFImageManager/Source/**/*.{h,m}"
        ss.exclude_files = "DFImageManager/Source/GIF/**/*.{h,m}"
    end

    s.subspec "GIF" do |ss|
        ss.dependency "DFImageManager/Core"
        ss.dependency "FLAnimatedImage", "~> 1.0"
        ss.source_files = "DFImageManager/Source/GIF/**/*.{h,m}"
    end

end
