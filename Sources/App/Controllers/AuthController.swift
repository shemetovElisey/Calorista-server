import Vapor
import Fluent
import JWT

// Контроллер для аутентификации
struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        
        // Защищенные маршруты
        let protected = auth.grouped(AuthMiddleware())
        protected.get("me", use: me)
        protected.put("me", use: updateProfile)
        protected.delete("logout", use: logout)
    }
    
    // POST /auth/register — регистрация пользователя
    func register(req: Request) async throws -> AuthResponse {
        try UserRegisterRequest.validate(content: req)
        let registerData = try req.content.decode(UserRegisterRequest.self)
        
        // Проверяем, что пользователь с таким email не существует
        if try await User.query(on: req.db).filter(\.$email == registerData.email).first() != nil {
            throw Abort(.conflict, reason: "User with this email already exists")
        }
        
        // Хешируем пароль
        let hashedPassword = try req.password.hash(registerData.password)
        
        // Создаем пользователя
        let user = User(
            email: registerData.email,
            username: registerData.email,
            passwordHash: hashedPassword,
            name: registerData.name
        )
        
        try await user.save(on: req.db)
        
        // Генерируем JWT токен
        let token = try req.jwt.sign(JWTToken(
            subject: .init(value: try user.requireID().uuidString),
            expiration: .init(value: Date().addingTimeInterval(86400))
        ))
        
        return AuthResponse(
            token: token,
            user: UserResponse(
                id: try user.requireID(),
                email: user.email,
                name: user.name,
                createdAt: user.createdAt
            )
        )
    }
    
    // POST /auth/login — вход пользователя
    func login(req: Request) async throws -> AuthResponse {
        try UserLoginRequest.validate(content: req)
        let loginData = try req.content.decode(UserLoginRequest.self)
        
        // Ищем пользователя по email
        guard let user = try await User.query(on: req.db).filter(\.$email == loginData.email).first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        // Проверяем пароль
        guard try req.password.verify(loginData.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid password")
        }
        
        // Генерируем JWT токен
        let token = try req.jwt.sign(JWTToken(
            subject: .init(value: try user.requireID().uuidString),
            expiration: .init(value: Date().addingTimeInterval(86400))
        ))
        
        return AuthResponse(
            token: token,
            user: UserResponse(
                id: try user.requireID(),
                email: user.email,
                name: user.name,
                createdAt: user.createdAt
            )
        )
    }
    
    // GET /auth/me — получить информацию о текущем пользователе
    func me(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        
        return UserResponse(
            id: try user.requireID(),
            email: user.email,
            name: user.name,
            createdAt: user.createdAt
        )
    }
    
    // PUT /auth/me — обновить профиль пользователя
    func updateProfile(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        
        // Здесь можно добавить логику обновления профиля
        // Пока просто возвращаем текущие данные
        return UserResponse(
            id: try user.requireID(),
            email: user.email,
            name: user.name,
            createdAt: user.createdAt
        )
    }
    
    // DELETE /auth/logout — выход из системы
    func logout(req: Request) async throws -> HTTPStatus {
        // В JWT аутентификации logout обычно реализуется на клиенте
        // путем удаления токена. Здесь можно добавить логику для
        // добавления токена в черный список, если необходимо.
        return .ok
    }
} 