//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation

public struct Path: CodingKey {
    public enum Component {
        case key(String)
        case index(Int)

        // swiftlint:disable:next force_try
        private static let regex = try! NSRegularExpression(pattern: "\\[(\\d)\\]")

        static func parse(string: String) -> [Component] {
            guard
                string.hasSuffix("]"),
                let range = string.range(of: "(\\[(\\d)\\])+$", options: .regularExpression)
            else {
                return [.key(string)]
            }

            let matches = regex.matches(in: string, range: NSRange(range, in: string))

            var components = [Component]()
            components.reserveCapacity(matches.count + 1)

            if range.lowerBound != string.startIndex {
                components.append(.key(String(string[..<range.lowerBound])))
            }

            for match in matches {
                guard match.numberOfRanges == 2 else { continue }

                guard let range = Range(match.range(at: 1), in: string), let index = Int(string[range]) else { continue }
                components.append(.index(index))
            }

            return components
        }
    }

    public init?(stringValue: String) {
        self.init(stringComponents: [stringValue])
    }

    public init(stringComponents: [String]) {
        self.components = stringComponents.flatMap { Component.parse(string: $0) }
    }

    public var stringValue: String {
        switch components[0] {
        case let .key(key): return key
        case let .index(index): return "Index \(index)"
        }
    }

    public var intValue: Int? {
        switch components[0] {
        case .key: return nil
        case let .index(idx): return idx
        }
    }

    public init?(intValue: Int) { return nil }

    public let components: [Component]

    public init(components: [Component]) {
        self.components = components
    }

    public var next: Path {
        var components = self.components
        _ = components.removeFirst()
        return Path(components: components)
    }
}

public extension Decoder {
    func decoder(by stringPath: String?) throws -> Decoder {
        guard let stringPath = stringPath else { return self }
        return try decoder(by: Path(stringComponents: stringPath.components(separatedBy: "/")))
    }

    func decoder(by path: Path) throws -> Decoder {
        var decoder: Decoder = self
        var path = path
        while path.components.count > 0 {
            if let index = path.intValue {
                var container = try decoder.unkeyedContainer()
                while container.currentIndex < index {
                    _ = try container.superDecoder()
                }
                decoder = try container.superDecoder()
            } else {
                decoder = try decoder.container(keyedBy: Path.self).superDecoder(forKey: path)
            }

            path = path.next
        }
        return decoder
    }
}
