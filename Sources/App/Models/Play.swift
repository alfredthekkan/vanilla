//
//  PlayAction.swift
//  App
//
//  Created by Alfred Thekkan on 28/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor

final class Play: PostgreSQLModel {
    var id: Int?
    
    var gameId: Int?
    var playerId: Int?
    var card: String?
    var is_trump_open: Bool?
    var created_at: Date?
    
    func cardObj() -> Card? {
        let comps = card?.components(separatedBy: "_")
        guard let sign = CardSign(rawValue: comps?.first ?? "") else { return nil }
        guard let value = CardValue(rawValue: comps?.last ?? "") else { return nil }
        return Card(sign: sign, value: value)
    }
}

extension Play: PostgreSQLMigration {}
extension Play: Content {}
