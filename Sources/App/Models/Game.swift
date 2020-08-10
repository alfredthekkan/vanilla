//
//  Game.swift
//  App
//
//  Created by Alfred Thekkan on 27/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor
import SwiftyBeaverVapor
import SwiftyBeaver

final class Game: PostgreSQLModel {
    var id: Int?
    
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    
    var teamAID: Int?
    var teamBID: Int?
    var nextPlayerID: Int?
    var nextDealerId: Int?
    var phase: String = "new"
    var is_trump_open: Bool?
    var playsRelation: Children<Game, Play> {
        return children(\.gameId)
    }
    var createdAt: Date?
    var updatedAt: Date?
    
    var bidRelation: Children<Game, Bid> {
        return children(\.gameId)
    }
    
    enum Event: String, Codable {
        case gameWon = "game_won"
        case roundWon = "round_won"
        case trumpOpen = "trump_open"
        case biddingFinished = "bidding_finished"
        case cardsInEarChanged = "cards_in_ear_changed"
        case distributeCards = "distribute_cards"
    }
    
    static func fullGame(_ request: Request, game: Game) throws -> Future<Game.Public> {
        
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        let publicGame = Game.Public()
        publicGame.gameId = game.id
        
        return Team.find(game.teamAID!, on: request).flatMap { team -> Future<Team.Public> in
            try team!.fullTeam(request: request)
        }.flatMap { publicTeam -> Future<Team?> in
            publicGame.teamA = publicTeam
            return Team.find(game.teamBID!, on: request)
        }.flatMap { team -> Future<Team.Public> in
            try team!.fullTeam(request: request)
        }.flatMap { publicTeam -> Future<[Bid]> in
            publicGame.teamB = publicTeam
            return try game.bidRelation.query(on: request).all()
        }.flatMap { bids -> Future<[Play]> in
            publicGame.bid = bids.first
            return try game.playsRelation.query(on: request).sort(\.created_at).all()
        }.map { plays -> Game.Public in
            publicGame.phase = game.phase
            publicGame.plays = plays
            publicGame.is_trump_open = game.is_trump_open
            publicGame.nextPlayerId = game.nextPlayerID
            publicGame.nextDealer = game.nextDealerId
            return publicGame
        }
    }
    
    struct Route {
        static let addActoin = "add_action"
        static let distribute = "distribute"
    }
    
    final class Public {
        let maxPoints = 40
        var nextDealer: Int?
        var gameId: Int?
        var teamA: Team.Public?
        var teamB: Team.Public?
        var nextPlayerId: Int?
        var phase: String?
        var is_trump_open: Bool?
        var plays: [Play] = []
        var bid: Bid?
        var event: Event?
        var isBiddingFinished: Bool {
            plays.count == 12 || bid?.points == self.maxPoints
        }
        
        
        var arrangedPlayers: RoundedArray<GamePlayer> {
            
            let arr = RoundedArray<GamePlayer>()
            for i in 0..<3 {
                arr.append(self.teamA!.players[i])
                arr.append(self.teamB!.players[i])
            }
            return arr
        }
        
        func updateNextPlayerForAction(_ action: PlayAction) {
            
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            
            let player = arrangedPlayers.elements.first { $0.playerId == action.playerId }
            if phase == "bid" {
                if isBiddingFinished {
                    if bid?.points == maxPoints {
                        self.nextPlayerId = bid?.player_id
                    } else {
                        self.nextPlayerId = plays[0].playerId
                    }
                } else {
                    self.nextPlayerId = arrangedPlayers.itemAfter(player!)?.playerId
                }
            } else if plays.count < 6 {
                self.nextPlayerId = arrangedPlayers.itemAfter(player!)?.playerId
            } else {
                //round is finished. so update points method will calculate the next player
            }
        }
        
        func processAction(_ action: PlayAction) {
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            switch action.action {
            case .bidCard:
                let bid = Bid()
                bid.id = self.bid?.id
                bid.card = action.card
                bid.gameId = self.gameId
                bid.player_id = action.playerId
                bid.points = action.points
                self.bid = bid
                let play = Play()
                play.playerId = action.playerId
                play.gameId = self.gameId
                play.card = action.card
                self.plays.append(play)
                
                updateNextPlayerForAction(action)
                
                if isBiddingFinished {
                    self.phase = "play"
                    self.plays.removeAll()
                    self.event = .biddingFinished
                }
                
            case .passBid:
               let play = Play()
                play.playerId = action.playerId
                play.gameId = self.gameId
                self.plays.append(play)
                
                updateNextPlayerForAction(action)
                
                if isBiddingFinished {
                    self.phase = "play"
                    self.plays.removeAll()
                    self.event = .biddingFinished
                }
            case .openTrump:
                self.is_trump_open = true
                self.event = .trumpOpen
            case .playCard:
                if plays.count == 12 || plays.count == 6 {
                    plays.removeAll()
                }
                let play = Play()
                play.is_trump_open = self.is_trump_open
                play.playerId = action.playerId
                play.gameId = self.gameId
                play.card = action.card
                self.plays.append(play)
                
                // Remove the card from the players hand
                arrangedPlayers.elements.first { (player) -> Bool in
                    player.playerId == play.playerId
                    }?.hand.removeAll(where: { (card) -> Bool in
                        card == play.card
                    })
                updateNextPlayerForAction(action)
                updatePoints()
                updateGameFinishStatusIfNeeded()
                print("Played card")
                
            default:
                print("Unhandled case")
            }
        }
        
        func startNewRound() {
            self.is_trump_open = false
            self.teamA?.points_in_round = 0
            self.teamB?.points_in_round = 0
            plays = []
            self.bid = nil
        }
        
        func updateGameFinishStatusIfNeeded() {
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            let bid = self.bid?.points ?? 0
            let bidder = self.bid?.player_id
            let isTeamA = self.teamA?.players.first { $0.playerId == bidder } != nil
            let team = isTeamA ? self.teamA: self.teamB
            let otherTeam = isTeamA ? self.teamB: self.teamA
            if team?.points_in_round ?? 0 >= bid {
                
                if bid == self.maxPoints {
                    // thani
                    team!.points_in_game = team!.points_in_game! + 3
                    otherTeam?.points_in_game = otherTeam!.points_in_game! - 3
                } else if bid >= 30 {
                    // honours bid
                    team!.points_in_game = team!.points_in_game! + 2
                    otherTeam?.points_in_game = otherTeam!.points_in_game! - 2
                } else {
                    // normal bid
                    team!.points_in_game = team!.points_in_game! + 1
                    otherTeam?.points_in_game = otherTeam!.points_in_game! - 1
                }
                // bidding team wins
                self.event = .gameWon
            } else if self.maxPoints - otherTeam!.points_in_round! < bid {
                // bidding team loses
                
                if bid == self.maxPoints {
                    // thani
                    team!.points_in_game = team!.points_in_game! - 4
                    otherTeam?.points_in_game = otherTeam!.points_in_game! + 4
                } else if bid >= 30 {
                    // honours bid
                    team!.points_in_game = team!.points_in_game! - 3
                    otherTeam?.points_in_game = otherTeam!.points_in_game! + 3
                } else {
                    // normal bid
                    team!.points_in_game = team!.points_in_game! - 2
                    otherTeam?.points_in_game = otherTeam!.points_in_game! + 2
                }
                self.event = .gameWon
            } else {
                // game contines
            }
            
            // condition for card in ear
            for team in [teamA, teamB] {
                if (team?.points_in_game ?? 0) <= 0 {
                    team?.players.forEach {
                        $0.cardsInEar = $0.cardsInEar + 1
                    }
                    team?.didAddCardToEarInThePreviousGame = true
                }
            }
            
            if self.event == .gameWon {
                self.phase = "new"
                let currentDealer = arrangedPlayers.elements.filter { $0.playerId == nextDealer }.first
                self.nextDealer =  arrangedPlayers.itemAfter(currentDealer!)?.playerId
                nextPlayerId = self.nextDealer
            }
        }
        
        func distributeCards() {
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            startNewRound()
            self.event = .distributeCards
            var cards = Card.allCards
            func randomHand() -> [String] {
                var cardsInHand: [String] = []
                while cardsInHand.count < 6 {
                    if let card = cards.randomElement() {
                        cardsInHand.append(card)
                        cards.removeAll { $0 == card }
                    }
                }
                return cardsInHand
            }
            arrangedPlayers.elements.forEach {
                $0.hand = randomHand()
            }
        }
        
        func updatePoints() {
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            guard plays.count == 6 else { return }
            self.event = .roundWon
            var winner = plays.first!
            var winningCard = plays.first?.cardObj()
            
            for i in 1..<plays.count {
                
                let play = plays[i]
                let card = play.cardObj()!
                var trump: CardSign?
                if play.is_trump_open == true {
                    let bid = self.bid!
                    trump = CardSign(rawValue: bid.card!.components(separatedBy: "_").first!)
                }
                if card.isGreaterThan(other: winningCard!, trump: trump) {
                    winningCard = card
                    winner = play
                }
            }
            self.nextPlayerId = winner.playerId
            
            let points = plays.reduce(0) { (result, play) -> Int in
                result + (play.cardObj()?.value.points ?? 0)
            }
            
            let isTeamA = self.teamA?.players.first { $0.playerId == winner.playerId } != nil
            let winningTeam = isTeamA ? self.teamA : self.teamB
            
            winningTeam!.points_in_round! += points
        }
        
        func save(request: Request) -> Future<HTTPStatus> {
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            
            return Game.find(self.gameId!, on: request).flatMap { game -> Future<Game> in
                           game?.phase = self.phase ?? ""
                           game?.nextPlayerID = self.nextPlayerId
                        game?.is_trump_open  = self.is_trump_open
                           return game!.save(on: request)
             }.flatMap { [weak self] _ -> Future<Any> in
                self!.teamA!.save(request: request)
             }.flatMap { [weak self] _ -> Future<Any> in
                self!.teamB!.save(request: request)
             }.flatMap {[weak self] _ -> Future<HTTPStatus> in
                if let bid = self?.bid {
                    return bid.save(on: request).transform(to: HTTPStatus.ok)
                }
                return request.future(HTTPStatus.ok)
             }.flatMap {[weak self] _ in
                Play.query(on: request).filter(\.gameId == self!.gameId ).delete()
             }.flatMap { [weak self] _ -> Future<HTTPStatus> in
                self!.plays.map {
                    $0.create(on: request)
                }.flatten(on: request).transform(to: HTTPStatus.ok)
            }
        }
        
        func joinPlayer(_ player: User) {
            let logger = SwiftyBeaver.self
            logger.debug(#function)

            let allPlayers = (self.teamA?.players ?? []) + (self.teamB?.players ?? [])
            guard allPlayers.first(where: { $0.playerId == player.id }) == nil else { return }
            
            let gamePlayer = GamePlayer(user: player)
            let teamAPlayerCount = self.teamA?.players.count ?? 0
            let teamBplayerCount = self.teamB?.players.count ?? 0
 
            if teamAPlayerCount == teamBplayerCount {
                self.teamA?.players.append(gamePlayer)
                gamePlayer.teamId = self.teamA?.id
            } else {
                self.teamB?.players.append(gamePlayer)
                gamePlayer.teamId = self.teamB?.id
            }
        }
    }
    
    deinit {
        print("Game is deallocated")
    }
}

extension Game: PostgreSQLMigration {}
extension Game: Content {}

extension Game.Public: Content {}

class RoundedArray<T: Equatable> {
    
    var elements: [T] = []
    
    func append(_ newElement: T) {
        elements.append(newElement)
    }
    
    func itemAfter(_ element: T) -> T? {
        let index = elements.firstIndex { $0 == element }
        if let idx = index {
            return elements[(idx + 1) % elements.count]
        }
        return nil
    }
    
    func itemBefore(_ element: T) -> T? {
        let index = elements.firstIndex { $0 == element }
        if let idx = index {
            return elements[(idx - 1 + elements.count) % elements.count]
        }
        return nil
    }
    
}
