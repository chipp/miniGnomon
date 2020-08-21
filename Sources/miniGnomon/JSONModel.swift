//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation
import SwiftyJSON

extension JSON {

    func xpath(_ path: String) throws -> JSON {
        guard path.count > 0 else { fatalError() }
        let components = path.components(separatedBy: "/")
        guard components.count > 0 else { return self }
        return try xpath(components)
    }

    private func xpath(_ components: [String]) throws -> JSON {
        guard let key = components.first else { return self }
        let value = self[key]
        guard value.exists() else {
            fatalError()
        }
        return try value.xpath(Array(components.dropFirst()))
    }

}

public protocol JSONModel: Model where DataContainer == JSON {
}

extension JSON: DataContainerProtocol {

    public typealias Iterator = GenericDataContainerIterator<JSON>

    public static func container(with data: Data, at path: String?) throws -> JSON {
        let json = try JSON(data: data)

        if let path = path {
            let xpathed = try json.xpath(path)
            if let error = xpathed.error {
                fatalError()
            }

            return xpathed
        } else {
            return json
        }
    }

    public func multiple() -> GenericDataContainerIterator<JSON>? {
        if let array = array {
            return .init(array)
        } else {
            return nil
        }
    }

    public static func empty() -> JSON {
        return JSON()
    }

}
