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
            hostName = "ec2-54-175-117-212.compute-1.amazonaws.com"
            port = 5432
            username = "klcwteqlqrmdag"
            database = "d10rit9bs0maq0"
            password = "1e02c6575b1183e33023f8a939600c6d4297ee4a3395ebb4aee8ea3c32ef6edd"
        }
        
        return PostgreSQLDatabaseConfig(hostname: hostName, port: port, username: username, database: database, password: password)
    }
}
