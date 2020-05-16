//
//  File.swift
//  App
//
//  Created by Alfred Thekkan on 16/05/2020.
//

import Foundation
import Vapor

struct User: Content {
    var email: String
    var password: String
}
