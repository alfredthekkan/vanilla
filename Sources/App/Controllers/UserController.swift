import Vapor
import Crypto
import SwiftyBeaverVapor
import SwiftyBeaver

final class UserController {

    func register(_ request: Request) throws -> Future<User.Public> {
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        return try request.content.decode(User.self).flatMap { player in
            let hasher = try request.make(BCryptDigest.self)
            let passwordHashed = try hasher.hash(player.password)
            let newPlayer = User(username: player.name, email: player.email, password: passwordHashed, platform: player.platform)
            newPlayer.sign_up_date = Date()
            newPlayer.last_logged_in_date = Date()
            
            return newPlayer.save(on: request).map { storedPlayer in
                return User.Public(id: storedPlayer.id ?? 0, email: storedPlayer.email, name: storedPlayer.name)
            }
        }
    }
    
    func login(_ request: Request) throws -> User.Public {
        let logger = try? request.sharedContainer.make(Logger.self)
        logger?.log(request.description, at: .verbose, file: #file, function: #function, line: #line, column: #column)

        do {
            let player = try request.requireAuthenticated(User.self)
            return User.Public(id: try player.requireID(), email: player.email, name: player.name)
        }catch {
            throw error
        }
        
    }
}
