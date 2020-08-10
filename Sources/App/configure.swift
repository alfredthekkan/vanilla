import Vapor
import FluentPostgreSQL
import Authentication
import Redis
import SwiftyBeaver
import SwiftyBeaverVapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    // Register providers first
    try services.register(PostgreSQLProvider())
    try services.register(AuthenticationProvider())
    try services.register(RedisProvider())
    
    // OR console and cloud platform logging
    let consoleDestination = ConsoleDestination()
    let cloudDestination = SBPlatformDestination(appID: "B1QM59", appSecret: "rtcghinuMf6sjqFifngpnzzfgwcpovjL", encryptionKey: "vwgyfihjjkjbHzhjAsaukkqgtowEk5t2")
    try services.register(SwiftyBeaverProvider(destinations: [consoleDestination, cloudDestination]))
    
    config.prefer(SwiftyBeaverVapor.self, for: Logger.self)
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a Postgre database
    // Configure a PostgreSQL database
    let postgresql = PostgreSQLDatabase(config: env.databaseConfig)
    /// Register the configured PostgreSQL database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: postgresql, as: .psql)
    
    let redisUrl = URL(string: "127.0.0.1")
    let redisDatabase = try RedisDatabase(url: redisUrl!)
    databases.add(database: redisDatabase, as: .redis)
    
    services.register(databases)
    
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Game.self, database: .psql)
    migrations.add(model: Team.self, database: .psql)
    migrations.add(model: GamePlayer.self, database: .psql)
    migrations.add(model: Play.self, database: .psql)
    migrations.add(model: Bid.self, database: .psql)
    migrations.add(model: TEST.self, database: .psql)
    migrations.add(model: TEST_CHILD.self, database: .psql)
    services.register(migrations)
    
    // Create a new NIO websocket server
    let wss = NIOWebSocketServer.default()

    // Register our server
    services.register(wss, as: WebSocketServer.self)
    wss.get("join_room_socket", Int.parameter, Int.parameter) { ws, req in
        // Add a new on text callback
        let roomId: Int = try req.parameters.next()
        let room = Room.find(id: roomId)
        room?.broadcastManger.clientSockets.append(ws)
        
        ws.onText { ws, text in
            // Simply echo any received text
            let roomId = text.components(separatedBy: ":").first ?? ""
            let message = text.components(separatedBy: ":").last ?? ""
            let room = Room.find(id: Int(roomId) ?? 0)
            room?.broadcastManger.clientSockets.forEach {
                $0.send(message)
            }
        }
        
        ws.onBinary { (ws, data) in
            do {
                let playAction = try JSONDecoder().decode(PlayAction.self, from: data)
                let roomId = playAction.roomId
                let room = Room.find(id: roomId ?? 0)
                room?.broadcastManger.clientSockets.forEach {
                    $0.send(data)
                }
                
            } catch {
                ws.send("Something wrong in data received")
            }
        }
    }
    
    let log = SwiftyBeaver.self
    if env.isRelease {
        log.debug("Production")
    } else {
        log.debug("Development")
    }
}

class PlayAction: Codable {
    
    enum Action: String {
        case joinRoom = "join_room"
        case bidCard = "bid_card"
        case passBid = "pass_bid"
        case openTrump = "open_trump"
        case playCard = "play_card"
    }
    
    var action: Action? {
        Action(rawValue: actn ?? "")
    }
    
    var playerId: Int?
    var roomId: Int?
    var actn: String?
    var card: String?
    var playerName: String?
    var points: Int?
    
    init(playerId: Int?, action: String?, card: String?) {
        self.playerId = playerId
        self.actn = action
        self.card = card
    }
}
