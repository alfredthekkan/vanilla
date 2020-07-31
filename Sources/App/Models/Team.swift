//
//  Team.swift
//  App
//
//  Created by Alfred Thekkan on 28/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor

final class Team: PostgreSQLModel {
    var id: Int?

    var gameId: Int?
    var pointsInGame: Int?
    var pointsInRound: Int?
    var didAddCardToEarInThePreviousGame: Bool = false
    
    func fullTeam(request: Request) throws -> Future<Team.Public> {
        do {
            return try playersRelation.query(on: request).sort(\.joined_at).all().map { players -> Team.Public in
                let publicTeam = Team.Public()
                publicTeam.id = self.id
                publicTeam.players = players
                publicTeam.points_in_game = self.pointsInGame
                publicTeam.points_in_round = self.pointsInRound
                return publicTeam
            }
        }catch {
            throw error
        }
    }
    
    final class Public {
        var id: Int?
        var points_in_game: Int?
        var points_in_round: Int?
        var didAddCardToEarInThePreviousGame: Bool?
        var players: [GamePlayer] = []
        
        func save(request: Request) -> Future<Any> {
            Team.find(id!, on: request).map { [weak self] team in
                team?.pointsInGame = self?.points_in_game ?? 0
                team?.pointsInRound = self?.points_in_round ?? 0
                team?.didAddCardToEarInThePreviousGame = self?.didAddCardToEarInThePreviousGame ?? false
             
                return request.transaction(on: .psql) { [weak self] conn -> Future<HTTPStatus> in
                    guard let strongSelf = self else { return request.future(HTTPStatus.ok)}
                    return team!.save(on: request)
                        .flatMap { _ in
                            strongSelf.savePlayerAtIndex(index: 0, request: request)
                    }.flatMap { _ in
                        return strongSelf.savePlayerAtIndex(index: 1, request: request)
                            .flatMap { _ in
                                return strongSelf.savePlayerAtIndex(index: 2, request: request)
                        }
                    }.transform(to: HTTPStatus.ok)
                }
            }
        }
        
        func savePlayerAtIndex(index: Int, request: Request) -> Future<HTTPStatus> {
            // Save first player
            if index < players.count {
                let player = players[index]
                return player.save(on: request).transform(to: HTTPStatus.ok)
            }
            return request.future(HTTPStatus.ok)
        }
    }
}

extension Team {
    var playersRelation: Children<Team, GamePlayer> {
        return children(\.teamId)
    }
}

extension Team: PostgreSQLMigration {}
extension Team: Content {}
extension Team.Public: Content {}
