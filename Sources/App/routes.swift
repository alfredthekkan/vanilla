import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("user") { req -> User in
        User(email: "alfredthekkan01@gmail.com", password: "Test1234")
    }
    
    router.post("createUser") { req -> Future<HTTPStatus> in
        try req.content.decode(User.self).map(to: HTTPStatus.self) { user in
            print(user.email)
            print(user.password)
            return .ok
        }
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
}
