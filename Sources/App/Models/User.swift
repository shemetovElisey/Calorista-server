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
    
    @Field(key: "created_at")
    var createdAt: Date
    
    @Field(key: "updated_at")
    var updatedAt: Date
    
    init() {}
    
    init(id: UUID? = nil, email: String, username: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.username = username
        self.passwordHash = passwordHash
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// DTO для регистрации пользователя
struct UserRegisterDTO: Content {
    let email: String
    let username: String
    let password: String
}

// DTO для входа пользователя
struct UserLoginDTO: Content {
    let email: String
    let password: String
}

// DTO для ответа с токеном
struct AuthResponse: Content {
    let user: User
    let token: String
}

// DTO для обновления пользователя
struct UserUpdateDTO: Content {
    let username: String?
    let email: String?
}

extension UserRegisterDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email, required: true)
        validations.add("username", as: String.self, is: .count(3...50), required: true)
        validations.add("password", as: String.self, is: .count(6...), required: true)
    }
}

extension UserLoginDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email, required: true)
        validations.add("password", as: String.self, is: !.empty, required: true)
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