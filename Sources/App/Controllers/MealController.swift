import Vapor
import Fluent

// Контроллер для работы с приёмами пищи
struct MealController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let meals = routes.grouped("meals")
            .grouped(AuthMiddleware()) // Защищаем все маршруты
        
        meals.get(use: getAll)
        meals.get(":mealID", use: getByID)
        meals.post(use: create)
        meals.delete(":mealID", use: delete)
    }
    
    // GET /meals — получить список всех приёмов пищи пользователя
    func getAll(req: Request) async throws -> [Meal] {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        
        return try await Meal.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .all()
    }
    
    // GET /meals/:id — получить конкретный приём пищи пользователя
    func getByID(req: Request) async throws -> Meal {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        guard let mealIDString = req.parameters.get("mealID"), let mealID = UUID(uuidString: mealIDString) else {
            throw Abort(.badRequest, reason: "Invalid meal ID")
        }
        guard let meal = try await Meal.query(on: req.db)
            .filter(\.$id == mealID)
            .filter(\.$user.$id == user.id!)
            .first() else {
            throw Abort(.notFound, reason: "Meal not found")
        }
        return meal
    }
    
    // POST /meals — создать новый приём пищи
    func create(req: Request) async throws -> Meal {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        
        try MealCreateDTO.validate(content: req)
        let dto = try req.content.decode(MealCreateDTO.self)
        
        let meal = Meal(
            userId: user.id!,
            name: dto.name,
            calories: dto.calories,
            carbohydrates: dto.carbohydrates,
            protein: dto.protein,
            fat: dto.fat,
            date: dto.date ?? Date()
        )
        
        try await meal.save(on: req.db)
        return meal
    }
    
    // DELETE /meals/:id — удалить приём пищи
    func delete(req: Request) async throws -> HTTPStatus {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        guard let mealIDString = req.parameters.get("mealID"), let mealID = UUID(uuidString: mealIDString) else {
            throw Abort(.badRequest, reason: "Invalid meal ID")
        }
        guard let meal = try await Meal.query(on: req.db)
            .filter(\.$id == mealID)
            .filter(\.$user.$id == user.id!)
            .first() else {
            throw Abort(.notFound, reason: "Meal not found")
        }
        try await meal.delete(on: req.db)
        return .noContent
    }
} 