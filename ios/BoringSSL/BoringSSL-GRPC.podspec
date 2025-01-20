Pod::Spec.new do |s|
  s.name     = 'BoringSSL-GRPC'
  s.version  = '0.0.32'
  s.summary  = 'BoringSSL is a fork of OpenSSL that is designed to meet Google\'s needs.'
  s.homepage = 'https://github.com/google/boringssl'
  s.license  = { :type => 'Mixed', :file => 'LICENSE' }
  s.authors  = 'Google Inc.'
  s.source   = { :git => 'https://github.com/google/boringssl.git', :commit => 'master' }
  s.ios.deployment_target = '13.0'
  
  s.source_files = 'src/**/*.{h,c,cc}'
  s.public_header_files = 'src/include/openssl/*.h'
  s.header_mappings_dir = 'src/include'
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/src/include"',
    'CLANG_WARN_DOCUMENTATION_COMMENTS' => 'NO',
  }
end 