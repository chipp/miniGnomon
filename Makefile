project:
	@swift package generate-xcodeproj
	@ruby fix_quick_objc_runtime.rb

test:
	@swift test --enable-test-discovery -Xswiftc -DTEST
