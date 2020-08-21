//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation

public protocol StringModel: Model where DataContainer == String {
    static var encoding: String.Encoding { get }
}

extension StringModel {

    public static func dataContainer(with data: Data, at path: String?) throws -> DataContainer {
        guard let string = String(data: data, encoding: encoding) else {
            fatalError()
        }
        return string
    }

}

extension String: DataContainerProtocol {

    public typealias Iterator = GenericDataContainerIterator<String>

    public static func container(with data: Data, at path: String?) throws -> String {
        fatalError()
    }

    public func multiple() -> GenericDataContainerIterator<String>? {
        return .init(components(separatedBy: .newlines))
    }

    public static func empty() -> String {
        return ""
    }

}

extension String: StringModel {
    public static var encoding: String.Encoding { return .utf8 }
}
