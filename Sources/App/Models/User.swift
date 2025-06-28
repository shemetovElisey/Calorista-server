import Vapor
import Fluent
import JWT

// Модель пользователя
final class User: Model, Content, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "name")
    var name: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, email: String, username: String, passwordHash: String, name: String) {
        self.id = id
        self.email = email
        self.username = username
        self.passwordHash = passwordHash
        self.name = name
    }
}

// DTO для регистрации пользователя
struct UserRegisterRequest: Content {
    let email: String
    let password: String
    let name: String
}

// DTO для входа пользователя
struct UserLoginRequest: Content {
    let email: String
    let password: String
}

// DTO для ответа с токеном
struct AuthResponse: Content {
    let token: String
    let user: UserResponse
}

// DTO для ответа с данными пользователя
struct UserResponse: Content {
    let id: UUID
    let email: String
    let name: String
    let createdAt: Date?
}

extension UserRegisterRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email, required: true)
        validations.add("password", as: String.self, is: .count(6...), required: true)
        validations.add("name", as: String.self, is: .count(3...50), required: true)
    }
}

extension UserLoginRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email, required: true)
        validations.add("password", as: String.self, is: .count(6...), required: true)
    }
}

// Расширение для работы с паролями
extension User {
    func generateToken(app: Application) throws -> String {
        let payload = JWTToken(
            subject: .init(value: self.id?.uuidString ?? ""),
            expiration: .init(value: Date().addingTimeInterval(86400))
        )
        return try app.jwt.signers.sign(payload)
    }
    
    static func hashPassword(_ password: String) throws -> String {
        try Bcrypt.hash(password)
    }
    
    func verifyPassword(_ password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
} 