//
//  Created by Vladimir Burdukov on 8/24/20.
//

import Foundation
import RxBlocking

let BlockingTimeout: TimeInterval = 0.5

extension MaterializedSequenceResult {
    func elements() throws -> [T] {
        switch self {
        case let .completed(elements):
            return elements
        case let .failed(_, error):
            throw error
        }
    }
}
