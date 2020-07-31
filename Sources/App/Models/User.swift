//
//  Player.swift
//  App
//
//  Created by Alfred Thekkan on 22/05/2020.
//

import Foundation
import FluentPostgreSQL
import Vapor
import Authentication

final class User: PostgreSQLModel {
    var id: Int?
    var name: String
    var email: String
    var password: String
    var sign_up_date: Date?
    var last_logged_in_date: Date?
    var roomId: Int?
    var platform: String?
    
    struct Public: Content {
        let id: Int
        let email: String
        let name: String
    }
    
    struct Route {
        static let login = "login"
        static let register = "register_player"
    }
    
    init(id: Int? = nil, username: String, email: String, password: String, platform: String?) {
        self.id = id
        self.name = username
        self.email = email
        self.password = password
        self.platform = platform
    }
}

extension User: PostgreSQLMigration {}
extension User: Content {}
extension User: BasicAuthenticatable {
    static var usernameKey: UsernameKey {
        return \.email
    }
    
    static var passwordKey: PasswordKey {
        return \.password
    }
}

