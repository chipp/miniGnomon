project:
	@swift package generate-xcodeproj
	@swift run --package-path=fix_project fix_project miniGnomon.xcodeproj

test:
	@swift test --enable-test-discovery -Xswiftc -DTEST
