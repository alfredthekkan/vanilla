//
//  PlayAction.swift
//  App
//
//  Created by Alfred Thekkan on 28/05/2020.
//

import Foundation
import FluentPostgreSQL

final class Play: PostgreSQLModel {
    var id: Int?
    
    var playerId: Int?
    var card: String?
}
