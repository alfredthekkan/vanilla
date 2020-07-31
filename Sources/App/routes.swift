import Vapor
import Crypto

struct PostgreSQLVersion: Codable {
    let version: String
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req -> Future<TEST.Public> in
        TEST.query(on: req).all().flatMap { (allTests) in
            let t = allTests.first
            return try t!.testsRelation.query(on: req).all().map { (test_children) -> (TEST.Public) in
                let publicTest = TEST.Public(test: t!)
                publicTest.alltests = test_children
                return publicTest
            }
        }
    }
    
    let userController = UserController()
    let roomController = RoomController()
    let gameController = GameController()
    
    let middleWare = User.basicAuthMiddleware(using: BCryptDigest())
    let authedGroup = router.grouped(middleWare)
    authedGroup.post(User.Route.login, use: userController.login)
    authedGroup.post(Room.Route.create, use: roomController.create)
    authedGroup.post(Room.Route.join, use: roomController.join)
    authedGroup.post(Room.Route.fetch, use: roomController.fetchGame)
    authedGroup.post(Game.Route.addActoin, use: gameController.addAction)
    authedGroup.post(Game.Route.distribute, use: gameController.distributeCards)
    router.post(User.Route.register, use: userController.register)

}

enum RecordError: Error {
    case notFound
}
