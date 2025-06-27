import Vapor
import JWT

// JWT токен для аутентификации
struct JWTToken: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
} 