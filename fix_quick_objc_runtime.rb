begin
  require 'xcodeproj'
rescue LoadError
  $stderr.puts 'Cannot find xcodeproj. Please install it `gem install xcodeproj`'
  exit 3
end

project_path = 'miniGnomon.xcodeproj'
project = Xcodeproj::Project.open project_path

quick_objc_runtime = project.targets.find { |t| t.name == 'QuickObjCRuntime' }

if quick_objc_runtime.nil?
  puts "Can't find target QuickObjCRuntime"
  exit 0
end

quick_objc_runtime.build_configurations.each do |config|
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
end

project.save project_path

puts 'Set CLANG_ENABLE_MODULES=YES for QuickObjCRuntime'