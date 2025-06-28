import Vapor
import JWT

// Middleware для аутентификации
struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let authHeader = request.headers.bearerAuthorization else {
            request.logger.warning("AuthMiddleware: Missing authorization header")
            throw Abort(.unauthorized, reason: "Missing authorization header")
        }
        
        let token = authHeader.token
        request.logger.info("AuthMiddleware: Processing token: \(token.prefix(20))...")
        
        do {
            let payload = try request.jwt.verify(token, as: JWTToken.self)
            request.logger.info("AuthMiddleware: Token verified successfully, subject: \(payload.subject.value)")
            
            guard let userID = UUID(uuidString: payload.subject.value) else {
                request.logger.warning("AuthMiddleware: Invalid UUID in token subject: \(payload.subject.value)")
                throw Abort(.unauthorized, reason: "Invalid token")
            }
            
            request.logger.info("AuthMiddleware: Looking for user with ID: \(userID)")
            guard let user = try await User.find(userID, on: request.db) else {
                request.logger.warning("AuthMiddleware: User not found with ID: \(userID)")
                throw Abort(.unauthorized, reason: "User not found")
            }
            
            request.logger.info("AuthMiddleware: User found: \(user.email)")
            // Добавляем пользователя в request для использования в контроллерах
            request.auth.login(user)
            
            return try await next.respond(to: request)
        } catch let abort as Abort {
            // Если это уже Abort ошибка, передаем её как есть
            request.logger.error("AuthMiddleware: Abort error: \(abort)")
            throw abort
        } catch let validation as ValidationsError {
            request.logger.error("AuthMiddleware: Validation error: \(validation)")
            throw validation
        } catch {
            request.logger.error("AuthMiddleware: Token verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Invalid token")
        }
    }
} 