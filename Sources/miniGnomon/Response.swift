//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation

public enum ResponseType {
    case localCache, httpCache, regular
}

public struct Response<M: Model> {
    public let result: M
    public let type: ResponseType
    public let headers: [String: String]
    public let statusCode: Int
}
