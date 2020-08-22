//
//  Created by Vladimir Burdukov on 8/22/20.
//

import Foundation
import XcodeProj

func fixClangModuleFlag(in target: PBXTarget) {
    guard let configurations = target.buildConfigurationList?.buildConfigurations else {
        print("cannot find build configurations for \(target.name) target", to: &StderrOutputStream.instance)
        exit(3)
    }

    for configuration in configurations {
        configuration.buildSettings["CLANG_ENABLE_MODULES"] = "YES"
    }
}
