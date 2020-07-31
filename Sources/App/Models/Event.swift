//
//  Event.swift
//  App
//
//  Created by Alfred Thekkan on 19/06/2020.
//

import Foundation
import Vapor

final class Event: Codable {
    
    enum EventType: String, Codable {
        case winMatch = "win_match"
        case winRound = "win_round"
    }
    
    var teamId: Int?
    var points: Int?
    var type: EventType?
}
extension Event: Content {}
