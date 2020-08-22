//
//  Created by Vladimir Burdukov on 8/22/20.
//

import Foundation
import XcodeProj
import PathKit

struct StderrOutputStream: TextOutputStream {
    static var instance = StderrOutputStream()

    func write(_ string: String) {
        fputs(string, stderr)
    }
}

let args = ProcessInfo.processInfo.arguments
guard args.count >= 2 else {
    print("usage: FixXcodeProject project.xcodeproj", to: &StderrOutputStream.instance)
    exit(1)
}

let projectPath = Path(args[1])
let project = try XcodeProj(path: projectPath)

guard let miniGnomon = project.pbxproj.targets(named: "miniGnomon").first else {
    print("cannot find target miniGnomon in \(projectPath)", to: &StderrOutputStream.instance)
    exit(2)
}

guard let quickObjCRuntime = project.pbxproj.targets(named: "QuickObjCRuntime").first else {
    print("cannot find target QuickObjCRuntime in \(projectPath)", to: &StderrOutputStream.instance)
    exit(2)
}

addTestFlag(to: miniGnomon)
print("Added TEST flag to miniGnomon target")

fixClangModuleFlag(in: quickObjCRuntime)
print("Set CLANG_ENABLE_MODULES=YES for QuickObjCRuntime")

try project.writePBXProj(path: projectPath, outputSettings: .init())
