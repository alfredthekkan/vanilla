import Vapor
import Crypto

final class UserController {

    func register(_ request: Request) throws -> Future<User.Public> {
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
        do {
            let player = try request.requireAuthenticated(User.self)
            return User.Public(id: try player.requireID(), email: player.email, name: player.name)
        }catch {
            throw error
        }
        
    }
}
