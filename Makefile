project:
	@swift package generate-xcodeproj

test:
	@swift test --enable-test-discovery -Xswiftc -DTEST
