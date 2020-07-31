//
//  Room.swift
//  App
//
//  Created by Alfred Thekkan on 23/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor
import Redis

final class Room {
    
    struct Route {
        static let create = "create_room"
        static let join = "join_room"
        static let fetch = "fetch_game"
    }
    
    var id: Int?
    var gameId: Int?
    
    var isFull: Bool {
        return broadcastManger.clientSockets.count == 6
    }
    
    var broadcastManger: BroadcastManager
    
    init(id: Int? = nil) {
        self.id = Room.activeRooms.count + 1000
        broadcastManger = BroadcastManager()
        Room.activeRooms.append(self)
    }
    
    func broadcastAction() {
        // get server
        // send message
    }
    
    static var activeRooms: [Room] = []
    
    struct Public: Content {
        var id: Int
    }
    
    static func find(id: Int) -> Room? {
        return Room.activeRooms.filter { $0.id == id }.first
    }
}
