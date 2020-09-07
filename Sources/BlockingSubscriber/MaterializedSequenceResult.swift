//
//  Created by Vladimir Burdukov on 9/6/20.
//

public enum MaterializedSequenceResult<Input, Failure: Error> {
    case completed(elements: [Input])
    case failed(elements: [Input], error: Failure)

    public func elements() throws -> [Input] {
        switch self {
        case let .completed(elements):
            return elements
        case let .failed(_, error):
            throw error
        }
    }
}

extension MaterializedSequenceResult: Equatable where Input: Equatable, Failure: Equatable {}
