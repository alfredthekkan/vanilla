//
//  BroadcastManager.swift
//  App
//
//  Created by Alfred Thekkan on 29/05/2020.
//

import Foundation
import Vapor

class BroadcastManager {
    
    var clientSockets: [WebSocket] = []
    var server: HTTPServer?
    
    init() {
        
    }
    
    func broadcast(_ action: PlayAction) {
        do {
            let data = try JSONEncoder().encode(action)
            clientSockets.forEach { $0.send(data) }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func broadcast(game: Game.Public) {
        do {
            let data = try JSONEncoder().encode(game)
            clientSockets.forEach { $0.send(data) }
        } catch {
            print(error.localizedDescription)
        }
    }
}

protocol Broadcastable {
    var asBroadcastString: String { get }
}

/// Echoes the request as a response.
struct EchoResponder: HTTPServerResponder {
    /// See `HTTPServerResponder`.
    func respond(to req: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
        // Create an HTTPResponse with the same body as the HTTPRequest
        let res = HTTPResponse(body: req.body)
        // We don't need to do any async work here, we can just
        // se the Worker's event-loop to create a succeeded future.
        return worker.eventLoop.newSucceededFuture(result: res)
    }
}
