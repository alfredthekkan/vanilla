//
//  Card.swift
//  App
//
//  Created by Alfred Thekkan on 28/05/2020.
//

import Foundation

struct Card {
    var sign: CardSign
    var value: CardValue
    
    static var allCards: [String] {
        return [
        "spade_3", "spade_7", "spade_8", "spade_9", "spade_10", "spade_J", "spade_Q", "spade_K", "spade_A",
         "club_3", "club_7", "club_8", "club_9", "club_10", "club_J", "club_Q", "club_K", "club_A",
         "diamond_3", "diamond_7", "diamond_8", "diamond_9", "diamond_10", "diamond_J", "diamond_Q", "diamond_K", "diamond_A",
         "heart_3", "heart_7", "heart_8", "heart_9", "heart_10", "heart_J", "heart_Q", "heart_K", "heart_A"
        ]
    }
    
    func isGreaterThan(other: Card, trump: CardSign?) -> Bool {
        let allValues = CardValue.allCases
        
        if self.sign == other.sign {
            let thisCardValue = allValues.index(of: self.value)
            let otherCardValue = allValues.index(of: other.value)
            if self.value.points == 3 && other.value.points == 3 {
                return false
            } else {
                return thisCardValue! > otherCardValue!
            }
        } else if trump != nil {
            return self.sign == trump
        } else {
            return false
        }
    }
}

enum CardSign: String {
    case spade = "spade"
    case clubs = "club"
    case diamond = "diamond"
    case hearts = "heart"
}

enum CardValue: String, CaseIterable {
    case seven = "7"
    case eight = "8"
    case queen = "Q"
    case king = "K"
    case ten = "10"
    case ace = "A"
    case nine = "9"
    case jack = "J"
    case three = "3"
    
    var points: Int {
        var points = 0
        switch self {
        case .three, .jack:
            points = 3
        case .nine:
            points = 2
        case .ten, .ace:
            points = 1
        case .seven, .eight, .queen, .king:
            points = 0
        }
        
        return points
    }
}
