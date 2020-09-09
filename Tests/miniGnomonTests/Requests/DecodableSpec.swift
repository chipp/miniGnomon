//
//  Created by Vladimir Burdukov on 8/21/20.
//

import XCTest
import Nimble

@testable import miniGnomon

class DecodableSpec: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testTeam() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                "name": "France",
                "players": [
                    [
                        "first_name": "Vasya", "last_name": "Pupkin"
                    ],
                    [
                        "first_name": "Petya", "last_name": "Ronaldo"
                    ]
                ]
            ], cached: false)
        }

        let request = try Request<TeamModel>(URLString: "https://example.com/")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let team = responses[0].result
        expect(team.name) == "France"
        expect(team.players[0].firstName) == "Vasya"
        expect(team.players[0].lastName) == "Pupkin"

        expect(team.players[1].firstName) == "Petya"
        expect(team.players[1].lastName) == "Ronaldo"
    }

    func testPlayers() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                [
                    "first_name": "Vasya", "last_name": "Pupkin"
                ],
                [
                    "first_name": "Petya", "last_name": "Ronaldo"
                ]
            ], cached: false)
        }

        let request = try Request<[PlayerModel]>(URLString: "https://example.com")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let players = responses[0].result

        expect(players).to(haveCount(2))

        expect(players[0]) == PlayerModel(firstName: "Vasya", lastName: "Pupkin")
        expect(players[1]) == PlayerModel(firstName: "Petya", lastName: "Ronaldo")
    }

    func testOptionalPlayers() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                [
                    "first_name": "Vasya", "last_name": "Pupkin"
                ],
                [
                    "first_name": "", "lastname": ""
                ]
            ], cached: false)
        }

        let request = try Request<[PlayerModel?]>(URLString: "https://example.com")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let players = responses[0].result

        expect(players).to(haveCount(2))

        expect(players[0]) == PlayerModel(firstName: "Vasya", lastName: "Pupkin")
        expect(players[1]).to(beNil())
    }

    func testMatchWithCustomizedDecoder() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                "homeTeam": [
                    "name": "France", "players": []
                ],
                "awayTeam": [
                    "name": "Belarus", "players": []
                ],
                "date": 1507654800
            ], cached: false)
        }

        let request = try Request<MatchModel>(URLString: "https://example.com")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let match = responses[0].result

        expect(match.homeTeam.name) == "France"
        expect(match.awayTeam.name) == "Belarus"

        var components = DateComponents()
        components.year = 2017
        components.month = 10
        components.day = 10
        components.hour = 19
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Europe/Paris")

        expect(match.date) == Calendar.current.date(from: components)
    }

    func testMatchesWithCustomizedDecoder() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                [
                    "homeTeam": [
                        "name": "France", "players": []
                    ],
                    "awayTeam": [
                        "name": "Belarus", "players": []
                    ],
                    "date": 1507654800
                ]
            ], cached: false)
        }

        let request = try Request<[MatchModel]>(URLString: "https://example.com")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))
        expect(responses[0].result).to(haveCount(1))

        let match = responses[0].result[0]

        expect(match.homeTeam.name) == "France"
        expect(match.awayTeam.name) == "Belarus"

        var components = DateComponents()
        components.year = 2017
        components.month = 10
        components.day = 10
        components.hour = 19
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Europe/Paris")

        expect(match.date) == Calendar.current.date(from: components)
    }

    func testXPath() throws {
        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: [
                "json": ["data": ["first_name": "Vasya", "last_name": "Pupkin"]]
            ], cached: false)
        }

        let request = try Request<PlayerModel>(URLString: "https://example.com/").setXPath("json/data")
        let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

        let responses = try result.elements()
        expect(responses).to(haveCount(1))

        let player = responses[0].result
        expect(player.firstName) == "Vasya"
        expect(player.lastName) == "Pupkin"
    }

    func testXPathWithArrayIndex() throws {
        let data = [
            "teams": [
                [
                    "name": "France",
                    "players": [
                        ["first_name": "Vasya", "last_name": "Pupkin"], ["first_name": "Petya", "last_name": "Ronaldo"]
                    ]
                ]
            ]
        ]

        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: data, cached: false)
        }

        do {
            let request = try Request<PlayerModel>(URLString: "https://example.com/")
                .setXPath("teams[0]/players[0]")
            let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

            let responses = try result.elements()
            expect(responses).to(haveCount(1))

            let player = responses[0].result
            expect(player.firstName) == "Vasya"
            expect(player.lastName) == "Pupkin"
        }

        do {
            let request = try Request<PlayerModel>(URLString: "https://example.com/")
                .setXPath("teams[0]/players[1]")
            let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

            let responses = try result.elements()
            expect(responses).to(haveCount(1))

            let player = responses[0].result
            expect(player.firstName) == "Petya"
            expect(player.lastName) == "Ronaldo"
        }
    }

    func testXPathWithMultipleArrayIndices() throws {
        let data = [
            "matches": [
                [
                    "id": 1,
                    "lineups": [
                        [
                            ["first_name": "Vasya", "last_name": "Pupkin"]
                        ],
                        [
                            ["first_name": "Vanya", "last_name": "Messi"], ["first_name": "Artem", "last_name": "Dzyuba"],
                        ]
                    ]
                ]
            ]
        ]

        let client = HTTPClient { _, _, _ in
            try! TestResponses.jsonResponse(result: data, cached: false)
        }

        do {
            let request = try Request<PlayerModel>(URLString: "https://example.com/")
                .setXPath("matches[0]/lineups[0][0]")
            let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

            let responses = try result.elements()
            expect(responses).to(haveCount(1))
            expect(responses[0].result) == PlayerModel(firstName: "Vasya", lastName: "Pupkin")
        }

        do {
            let request = try Request<PlayerModel>(URLString: "https://example.com/")
                .setXPath("matches[0]/lineups[1][1]")
            let result = try client.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

            let responses = try result.elements()
            expect(responses).to(haveCount(1))
            expect(responses[0].result) == PlayerModel(firstName: "Artem", lastName: "Dzyuba")
        }
    }

}
