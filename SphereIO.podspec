Pod::Spec.new do |s|
  s.name         = "SphereIO"
  s.version      = "0.0.1"
  s.summary      = "An incomplete and mostly wrong Sphere.IO API client written in Swift."
  s.license      = "MIT"
  s.authors      = { "Boris Bügling" => "boris@buegling.com" }
  s.homepage     = "https://github.com/contentful-labs/Wunderschnell"
  s.source       = { :git => "https://github.com/contentful-labs/Wunderschnell.git", :tag => s.version }

  s.requires_arc = true
  s.source_files = "Phone App/{Product.swift,SphereIOClient.swift}"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  s.dependency 'Alamofire'
  s.dependency 'Result'
end
