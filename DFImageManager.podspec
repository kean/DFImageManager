Pod::Spec.new do |s|
    s.name         = 'DFImageManager'
    s.version      = '1.0.0'
    s.summary      = 'Advanced framework for managing images. Zero config, yet immense customization.'
    s.description = <<-DESC
                    Advanced framework for loading, caching, processing, displaying and preheating images. DFImageManager is a pipeline that loads images using multiple dependencies which can be injected in runtime. It features optional AFNetworking, FLAnimatedImage and WebP integration.
                    DESC
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.homepage     = 'https://github.com/kean/DFImageManager'
    s.author             = 'Alexander Grebenyuk'
    s.social_media_url   = 'https://twitter.com/a_grebenyuk'
    s.ios.deployment_target = '8.0'
    s.watchos.deployment_target = '2.0'
    s.source       = { :git => 'https://github.com/kean/DFImageManager.git', :tag => s.version.to_s }
    s.requires_arc = true
    s.default_subspecs = 'Core', 'UI'

    s.subspec 'Core' do |ss|
        ss.source_files  = 'Pod/Source/Core/**/*.{h,m}'
        ss.private_header_files = 'Pod/Source/Core/Private/*.h'
    end

    s.subspec 'UI' do |ss|
        ss.ios.deployment_target = '8.0'
        ss.dependency 'DFImageManager/Core'
        ss.ios.source_files = 'Pod/Source/UI/**/*.{h,m}'
    end

    s.subspec 'AFNetworking' do |ss|
        ss.ios.deployment_target = '8.0'
        ss.prefix_header_contents = '#define DF_SUBSPEC_AFNETWORKING_ENABLED 1'
        ss.dependency 'DFImageManager/Core'
        ss.dependency 'AFNetworking/NSURLSession', '~> 2.0'
        ss.source_files = 'Pod/Source/AFNetworking/**/*.{h,m}'
    end

    s.subspec 'PhotosKit' do |ss|
        ss.ios.deployment_target = '8.0'
        ss.prefix_header_contents = '#define DF_SUBSPEC_PHOTOSKIT_ENABLED 1'
        ss.dependency 'DFImageManager/Core'
        ss.source_files = 'Pod/Source/PhotosKit/**/*.{h,m}'
    end

    s.subspec 'GIF' do |ss|
        ss.ios.deployment_target = '8.0'
        ss.prefix_header_contents = '#define DF_SUBSPEC_GIF_ENABLED 1'
        ss.dependency 'DFImageManager/Core'
        ss.dependency 'DFImageManager/UI'
        ss.dependency 'FLAnimatedImage', '~> 1.0'
        ss.source_files = 'Pod/Source/GIF/**/*.{h,m}'
    end

    s.subspec 'WebP' do |ss|
        ss.ios.deployment_target = '8.0'
        ss.prefix_header_contents = '#define DF_SUBSPEC_WEBP_ENABLED 1'
        ss.dependency 'DFImageManager/Core'
        ss.dependency 'libwebp'
        ss.source_files = 'Pod/Source/WebP/**/*.{h,m}'
    end
end
