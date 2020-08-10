//
//  File.swift
//  App
//
//  Created by Alfred Thekkan on 30/05/2020.
//

import Foundation
import Vapor
import SwiftyBeaverVapor
import SwiftyBeaver

final class RoomController {
    
    func create(request: Request) throws -> Future<Room.Public> {
        
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        
        do {
            let user = try request.requireAuthenticated(User.self)
            
            let newGame = Game()
            newGame.nextPlayerID = user.id
            newGame.nextDealerId = user.id
            let teamA = Team()
            
            return teamA.save(on: request).flatMap { team -> Future<GamePlayer> in
                newGame.teamAID = team.id
                let player1: GamePlayer = GamePlayer(user: user)
                player1.teamId = team.id
                return player1.save(on: request)
            }.flatMap { _ -> Future<Team> in
                let teamB = Team()
                return teamB.save(on: request)
            }.flatMap { team -> Future<Game> in
                newGame.teamBID = team.id
                newGame.nextDealerId = user.id
                return newGame.save(on: request)
            }.map { game -> Room.Public in
                let room = Room()
                room.gameId = game.id
                return Room.Public(id: room.id!)
            }
        } catch {
            throw error
        }
    }
    
    func joinn(request: Request) throws -> Future<Game.Public> {
        
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        do {
            let user = try request.requireAuthenticated(User.self)
            var currentGame: Game?

            var room: Room?
            return try request.content.decode(JoinRoomRequest.self).flatMap { roomRequest -> Future<Game?> in
                room = Room.find(id: roomRequest.roomId)
                return Game.find(room!.gameId!, on: request)
            }.flatMap { game -> Future<Team?> in
                currentGame = game
                return Team.find(game!.teamAID!, on: request)
            }.flatMap { team -> Future<[GamePlayer]> in
                try team!.playersRelation.query(on: request).all()
            }.flatMap { players -> Future<Game.Public> in
                let newPlayer = GamePlayer(user: user)
                newPlayer.teamId = players.count == 3 ? currentGame?.teamBID : currentGame?.teamAID
                return newPlayer.save(on: request).flatMap { _ in
                    Team.find(currentGame!.teamBID!, on: request)
                }.flatMap { team in
                    try team!.playersRelation.query(on: request).all()
                }.flatMap { players -> Future<Game.Public> in
                    let controller = GameController()
                    return try controller.fetchGame(request: request)
                }
            }.map { game -> Game.Public in
                (room?.broadcastManger.broadcast(game: game))!
                return game
            }
        }
        catch {
            throw error
        }
    }
    
    func join(request: Request) throws -> Future<Game.Public> {
        // get user
        // get game
        // add player to team A or team B
        // broadcast to all players
        
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        
        do {
            let user = try request.requireAuthenticated(User.self)

            var room: Room?
            return try request.content.decode(JoinRoomRequest.self).flatMap { roomRequest -> Future<Game?> in
                room = Room.find(id: roomRequest.roomId)
                if room == nil {
                    throw ThurupError.roomNotFound
//                    throw Abort(.notFound, reason: "Invalid Room Id")
                }
                return Game.find(room!.gameId!, on: request)
            }.flatMap { game -> Future<Game.Public> in
                try Game.fullGame(request, game: game!)
            }.flatMap { fullGame -> Future<Game.Public> in
                fullGame.joinPlayer(user)
                (room?.broadcastManger.broadcast(game: fullGame))!
                return fullGame.save(request: request).map { status -> Game.Public in
                    return fullGame
                }
            }
        }
        catch {
            throw error
        }
    }
    
    func fetchGame(request: Request) throws -> Future<Game.Public> {
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        do {
            let _ = try request.requireAuthenticated(User.self)
            
            return try request.content.decode(JoinRoomRequest.self).flatMap { roomRequest -> Future<Game?> in
                guard let room = Room.find(id: roomRequest.roomId) else { throw ThurupError.roomNotFound }
                return Game.find(room.gameId!, on: request)
            }.flatMap { game -> Future<Game.Public> in
                try Game.fullGame(request, game: game!)
            }
        } catch {
            throw error
        }
    }
    
    func fetch(request: Request) throws -> Future<Room.Public> {
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        return try request.content.decode(JoinRoomRequest.self).map { roomRequest in
            _ = try request.requireAuthenticated(User.self)
            let room = Room.find(id: roomRequest.roomId)
            //access game and append player to game
            return Room.Public(id: room!.id!)
        }
    }
}

extension RoomController {
    func joinUser(user: User?, room: Room?) {
    
        let log = SwiftyBeaver.self
        log.debug(#function)
        
        guard let room = room, let user = user else { return }
        let action = PlayAction(playerId: user.id, action: "join_room", card: nil)
        action.playerName = user.name
        room.broadcastManger.broadcast(action)
    }
}

extension NSError: Debuggable {
    public var identifier: String {
        return self.domain
    }
    
    public var reason: String {
        return self.localizedDescription
    }
    
    static let roomNotFound = NSError(domain: "com.room.notFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid Room ID. Please check!"])
}

enum ThurupError: String {
    case roomNotFound = "roomNotFound"
}

extension ThurupError: AbortError {
    var status: HTTPResponseStatus {
        switch self {
        case .roomNotFound:
            return .notFound
        }
    }
    
    var reason: String {
        switch self {
        case .roomNotFound:
            return "Invalid Room ID"
        }
    }
    
    var identifier: String {
        return self.rawValue
    }
}
