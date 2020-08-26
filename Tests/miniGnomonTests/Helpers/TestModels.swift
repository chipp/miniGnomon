//
//  Created by Vladimir Burdukov on 8/21/20.
//

import Foundation
import miniGnomon

struct TestModel: DecodableModel {
    let key: Int
}

struct PlayerModel: DecodableModel, Equatable {

    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }

    static func ==(lhs: PlayerModel, rhs: PlayerModel) -> Bool {
        return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
    }

}

struct TeamModel: DecodableModel {

    let name: String
    let players: [PlayerModel]

}

struct MatchModel: DecodableModel {

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    let homeTeam: TeamModel
    let awayTeam: TeamModel

    let date: Date

}
