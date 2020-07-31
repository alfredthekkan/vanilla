//
//  GameController.swift
//  App
//
//  Created by Alfred Thekkan on 13/06/2020.
//

import Vapor

final class GameController {
    
    
    func addAction(request: Request) throws -> Future<Game.Public> {
        do {
            var actn: PlayAction?
            let user = try request.requireAuthenticated(User.self)
            return try request.content.decode(PlayAction.self).flatMap { action -> Future<Game?> in
                let room = Room.find(id: action.roomId ?? 0)
                actn = action
                return Game.find(room?.gameId ?? 0, on: request)
            }.flatMap { game -> Future<Game.Public> in
                try Game.fullGame(request, game: game!)
            }.flatMap { fullGame in
                actn?.playerId =  user.id
                fullGame.processAction(actn!)
                Room.find(id: actn?.roomId ?? 0)?.broadcastManger.broadcast(game: fullGame)
                return fullGame.save(request: request).flatMap { _ in
                    request.future(fullGame)
                }
            }
        } catch {
            throw error
        }
    }
    
    func fetchGame(request: Request) throws -> Future<Game.Public> {
          do {
              let _ = try request.requireAuthenticated(User.self)
              
              return try request.content.decode(JoinRoomRequest.self).flatMap { roomRequest -> Future<Game?> in
                  let room = Room.find(id: roomRequest.roomId)
                  return Game.find(room!.gameId!, on: request)
              }.flatMap { game -> Future<Game.Public> in
                  try Game.fullGame(request, game: game!)
              }
          } catch {
              throw error
          }
      }

    func distributeCards(request: Request) throws -> Future<Game.Public> {
        
        do {
            return try fetchGame(request: request).flatMap { game -> Future<Game.Public> in
                game.distributeCards()
                game.phase = "bid"
                game.plays.removeAll()
                return try request.content.decode(JoinRoomRequest.self).flatMap { roomRequest in
                    Room.find(id: roomRequest.roomId)?.broadcastManger.broadcast(game: game)
                    return game.save(request: request).flatMap { _ in
                        request.future(game)
                    }
                }
            }
        } catch {
            throw error
        }
        /*
        var cards = Card.allCards
        
        var teamACards: [String] = []
        var teamBCards: [String] = []

        while cards.count > 0 {
            var card = cards.randomElement()!
            cards.removeAll { $0 == card }
            teamACards.append(card)
            card = cards.randomElement()!
            cards.removeAll { $0 == card }
            teamBCards.append(card)
        }
        
        func distributeCardsFor(teamId: Int, cards: [String], request: Request) -> Future<HTTPStatus> {
            
            var allCardsForTeam = cards
            
            func getRandomCards() -> [String] {
                var arr = [String]()
                for _ in 0..<6 {
                    let card = allCardsForTeam.randomElement()!
                    allCardsForTeam.removeAll { $0 == card }
                    arr.append(card)
                }
                return arr
            }
            
            return Team.find(teamId, on: request)
                .flatMap { team -> Future<[GamePlayer]> in
                    try team!.playersRelation.query(on: request).all()
            }.flatMap { players -> Future<HTTPStatus> in
                players.forEach {
                    $0.hand = getRandomCards()
                }
                return request.transaction(on: .psql) { conn in
                    players[0].save(on: conn).flatMap { _ in
                        players[1].save(on: conn).flatMap { _ in
                            players[2].save(on: conn)
                        }
                    }
                }.transform(to: HTTPStatus.ok)
            }
        }
        
        do {
            return try request.content.decode(JoinRoomRequest.self).flatMap { roomRequest -> Future<Game?> in
                let room = Room.find(id: roomRequest.roomId)
                return Game.find(room?.gameId ?? 0, on: request)
            }.flatMap { game in
                try Game.fullGame(request, game: game)
            }
        }catch {
            throw error
        }
 */
    }
}
