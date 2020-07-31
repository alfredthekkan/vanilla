//
//  GamePlayer.swift
//  App
//
//  Created by Alfred Thekkan on 28/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor

final class GamePlayer: PostgreSQLModel {
    var id: Int?
    var playerId: Int?
    var name: String?
    var teamId: Int?
    var hand: [String]
    var cardsInEar: Int
    var joined_at: Date?
    
    init(user: User) {
        self.playerId = user.id
        self.name = user.name
        hand = []
        cardsInEar = 0
    }
}

extension GamePlayer: PostgreSQLMigration {}
extension GamePlayer: Content {}
extension GamePlayer: Equatable {
    static func == (lhs: GamePlayer, rhs: GamePlayer) -> Bool {
        return lhs.playerId == rhs.playerId
    }
}
