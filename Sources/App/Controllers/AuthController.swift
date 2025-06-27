import Vapor
import Fluent

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
        try UserRegisterDTO.validate(content: req)
        let dto = try req.content.decode(UserRegisterDTO.self)
        
        // Проверяем, что email не занят
        if try await User.query(on: req.db)
            .filter(\.$email == dto.email)
            .first() != nil {
            throw Abort(.conflict, reason: "Email already exists")
        }
        
        // Проверяем, что username не занят
        if try await User.query(on: req.db)
            .filter(\.$username == dto.username)
            .first() != nil {
            throw Abort(.conflict, reason: "Username already exists")
        }
        
        // Хешируем пароль
        let hashedPassword = try User.hashPassword(dto.password)
        
        // Создаем пользователя
        let user = User(
            email: dto.email,
            username: dto.username,
            passwordHash: hashedPassword
        )
        
        try await user.save(on: req.db)
        
        // Генерируем токен
        let token = try user.generateToken(app: req.application)
        
        return AuthResponse(user: user, token: token)
    }
    
    // POST /auth/login — вход пользователя
    func login(req: Request) async throws -> AuthResponse {
        try UserLoginDTO.validate(content: req)
        let dto = try req.content.decode(UserLoginDTO.self)
        
        // Ищем пользователя по email
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == dto.email)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        // Проверяем пароль
        guard try user.verifyPassword(dto.password) else {
            throw Abort(.unauthorized, reason: "Invalid password")
        }
        
        // Генерируем токен
        let token = try user.generateToken(app: req.application)
        
        return AuthResponse(user: user, token: token)
    }
    
    // GET /auth/me — получить информацию о текущем пользователе
    func me(req: Request) async throws -> User {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        return user
    }
    
    // PUT /auth/me — обновить профиль пользователя
    func updateProfile(req: Request) async throws -> User {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        
        let dto = try req.content.decode(UserUpdateDTO.self)
        
        // Обновляем поля, если они предоставлены
        if let username = dto.username {
            // Проверяем, что username не занят другим пользователем
            if try await User.query(on: req.db)
                .filter(\.$username == username)
                .filter(\.$id != user.id!)
                .first() != nil {
                throw Abort(.conflict, reason: "Username already exists")
            }
            user.username = username
        }
        
        if let email = dto.email {
            // Проверяем, что email не занят другим пользователем
            if try await User.query(on: req.db)
                .filter(\.$email == email)
                .filter(\.$id != user.id!)
                .first() != nil {
                throw Abort(.conflict, reason: "Email already exists")
            }
            user.email = email
        }
        
        user.updatedAt = Date()
        try await user.save(on: req.db)
        
        return user
    }
    
    // DELETE /auth/logout — выход пользователя (опционально)
    func logout(req: Request) async throws -> HTTPStatus {
        // В JWT аутентификации logout обычно реализуется на клиенте
        // путем удаления токена, но здесь можно добавить логику
        // для blacklist токенов, если нужно
        return .ok
    }
} 