//
//  Database.swift
//  App
//
//  Created by Alfred Thekkan on 22/05/2020.
//

import Vapor
import Foundation
import PostgreSQL

extension Environment {
    var databaseConfig: PostgreSQLDatabaseConfig {
        
        var hostName: String
        var port: Int
        var username: String
        var database: String
        var password: String?
        switch self {
        case .development:
            hostName = "localhost"
            port = 5433
            username = "postgres"
            database = "forty"
            password = "May@2014"
        default:
            hostName = "localhost"
            port = 5433
            username = "postgres"
            database = "forty"
            password = "May@2014"
        }
        
        return PostgreSQLDatabaseConfig(hostname: hostName, port: port, username: username, database: database, password: password)
    }
}
