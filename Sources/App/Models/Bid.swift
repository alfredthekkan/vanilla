//
//  Bid.swift
//  App
//
//  Created by Alfred Thekkan on 28/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor

//class Bid {
//    var points: Int
//    var player: GamePlayer
//    var card: Card
//
//    var gamePointsOnWin: Int {
//        if points == 40 {
//            return 3
//        } else if points > 30 {
//            return 2
//        } else {
//            return 1
//        }
//    }
//
//    var gamePointsOnLoose: Int {
//        if points == 40 {
//            return -4
//        } else if points > 30 {
//            return -3
//        } else {
//            return -2
//        }
//    }
//
//    init(points: Int, player: GamePlayer, card: Card) {
//        self.points = points
//        self.player = player
//        self.card = card
//    }
//}

final class Bid: PostgreSQLModel {
    var id: Int?
    var gameId: Int?
    var player_id: Int?
    var card: String?
    var points: Int?
}

extension Bid: Content {}
extension Bid: PostgreSQLMigration {}

final class TEST: PostgreSQLModel {
    var id: Int?
    var name = "Alfred P Thekkan"
    
    final class Public: Content {
        var alltests: [TEST_CHILD] = []
        var id: Int?
        var name: String
        
        init(test: TEST) {
            self.id = test.id
            self.name = test.name
        }
       
    }
}

extension TEST: PostgreSQLMigration {}
extension TEST: Content {}
extension TEST {
    var testsRelation: Children<TEST, TEST_CHILD> {
        return children(\.test_id)
    }
}


final class TEST_CHILD: PostgreSQLModel {
    var id: Int?
    var test_id: Int
    var child_name = "Alfred P Thekkan"
}

extension TEST_CHILD {
    var parentTest: Parent<TEST_CHILD, TEST> {
        return parent(\.test_id)
    }
}

extension TEST_CHILD: PostgreSQLMigration {}
extension TEST_CHILD: Content {}


