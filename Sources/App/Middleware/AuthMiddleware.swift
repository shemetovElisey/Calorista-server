import Vapor
import JWT

// Middleware для аутентификации
struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let authHeader = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing authorization header")
        }
        
        let token = authHeader.token
        
        do {
            let payload = try request.jwt.verify(token, as: JWTToken.self)
            
            guard let userID = UUID(uuidString: payload.subject.value) else {
                throw Abort(.unauthorized, reason: "Invalid token")
            }
            
            guard let user = try await User.find(userID, on: request.db) else {
                throw Abort(.unauthorized, reason: "User not found")
            }
            
            // Добавляем пользователя в request для использования в контроллерах
            request.auth.login(user)
            
            return try await next.respond(to: request)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid token")
        }
    }
} 