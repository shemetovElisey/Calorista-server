import Vapor

struct APIKeyMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        // Исключаем маршрут документации из проверки API ключа
        if request.url.path.hasPrefix("/docs") {
            return next.respond(to: request)
        }
        
        // Получаем ожидаемый API ключ из переменной окружения или используем значение по умолчанию
        let expectedApiKey = Environment.get("API_KEY") ?? "default-secret-key-2024"
        
        // Логируем для отладки
        request.logger.info("API Key Middleware: Expected key = \(expectedApiKey)")
        
        // Получаем API ключ из заголовка запроса
        guard let requestApiKey = request.headers.first(name: "X-API-Key") else {
            request.logger.warning("API Key Middleware: Missing API key")
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Missing API key"))
        }
        
        request.logger.info("API Key Middleware: Request key = \(requestApiKey)")
        
        // Проверяем, что API ключ совпадает с ожидаемым
        guard requestApiKey == expectedApiKey else {
            request.logger.warning("API Key Middleware: Invalid API key")
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Invalid API key"))
        }
        
        request.logger.info("API Key Middleware: API key validated successfully")
        return next.respond(to: request)
    }
} 