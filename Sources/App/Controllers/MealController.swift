import Vapor
import Fluent

// Контроллер для работы с приёмами пищи
struct MealController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let meals = routes.grouped("meals")
            .grouped(AuthMiddleware()) // Защищаем все маршруты
        
        meals.get(use: index)
        meals.post(use: create)
        meals.get("test", use: test) // Добавляем тестовый эндпоинт
        
        meals.group(":mealID") { meal in
            meal.get(use: show)
            meal.put(use: update)
            meal.delete(use: delete)
        }
    }
    
    // GET /meals — получить список всех приёмов пищи пользователя
    func index(req: Request) async throws -> [MealResponse] {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        
        let meals = try await Meal.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$date, .descending)
            .all()
        
        return try meals.map { meal in
            MealResponse(
                id: try meal.requireID(),
                name: meal.name,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat,
                date: meal.date,
                createdAt: meal.createdAt,
                updatedAt: meal.updatedAt
            )
        }
    }
    
    // GET /meals/:id — получить конкретный приём пищи пользователя
    func show(req: Request) async throws -> MealResponse {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let mealID = req.parameters.get("mealID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid meal ID")
        }
        
        guard let meal = try await Meal.query(on: req.db)
            .filter(\.$id == mealID)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Meal not found")
        }
        
        return MealResponse(
            id: try meal.requireID(),
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            date: meal.date,
            createdAt: meal.createdAt,
            updatedAt: meal.updatedAt
        )
    }
    
    // POST /meals — создать новый приём пищи
    func create(req: Request) async throws -> MealResponse {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        try MealCreateRequest.validate(content: req)
        let mealData = try req.content.decode(MealCreateRequest.self)
        
        let meal = Meal(
            userId: userId,
            name: mealData.name,
            calories: mealData.calories,
            protein: mealData.protein,
            carbs: mealData.carbs,
            fat: mealData.fat,
            date: mealData.date
        )
        
        try await meal.save(on: req.db)
        
        return MealResponse(
            id: try meal.requireID(),
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            date: meal.date,
            createdAt: meal.createdAt,
            updatedAt: meal.updatedAt
        )
    }
    
    // PUT /meals/:id — обновить приём пищи
    func update(req: Request) async throws -> MealResponse {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let mealID = req.parameters.get("mealID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid meal ID")
        }
        
        try MealCreateRequest.validate(content: req)
        let mealData = try req.content.decode(MealCreateRequest.self)
        
        guard let meal = try await Meal.query(on: req.db)
            .filter(\.$id == mealID)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Meal not found")
        }
        
        meal.name = mealData.name
        meal.calories = mealData.calories
        meal.protein = mealData.protein
        meal.carbs = mealData.carbs
        meal.fat = mealData.fat
        meal.date = mealData.date
        
        try await meal.save(on: req.db)
        
        return MealResponse(
            id: try meal.requireID(),
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            date: meal.date,
            createdAt: meal.createdAt,
            updatedAt: meal.updatedAt
        )
    }
    
    // DELETE /meals/:id — удалить приём пищи
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let mealID = req.parameters.get("mealID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid meal ID")
        }
        
        guard let meal = try await Meal.query(on: req.db)
            .filter(\.$id == mealID)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Meal not found")
        }
        
        try await meal.delete(on: req.db)
        return .noContent
    }
    
    // GET /meals/test — тестовый эндпоинт для отладки
    func test(req: Request) async throws -> [String: String] {
        let user = try req.auth.require(User.self)
        return [
            "message": "AuthMiddleware работает!",
            "user_id": try user.requireID().uuidString,
            "user_email": user.email
        ]
    }
} 