import Vapor
import Fluent

// Контроллер для работы с продуктами
struct ProductController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let products = routes.grouped("products")
            .grouped(AuthMiddleware()) // Защищаем все маршруты
        
        products.get("search", use: search)
        products.get("barcode", ":barcode", use: getByBarcode)
        products.post("meal", use: createMealWithProduct)
    }
    
    // GET /products/search?query=... — поиск продуктов
    func search(req: Request) async throws -> ProductSearchResponse {
        let user = try req.auth.require(User.self)
        
        guard let query = req.query[String.self, at: "query"], !query.isEmpty else {
            throw Abort(.badRequest, reason: "Query parameter is required")
        }
        
        // Сначала ищем в локальной БД
        let localProducts = try await Product.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$name ~~ query)
                group.filter(\.$brand ~~ query)
            }
            .limit(20)
            .all()
        
        if !localProducts.isEmpty {
            return ProductSearchResponse(
                products: localProducts,
                total: localProducts.count,
                fromCache: true
            )
        }
        
        // Если в локальной БД нет, ищем через Open Food Facts API
        var offService = OpenFoodFactsService()
        let products = try await offService.searchProducts(query: query, on: req)
        
        // Сохраняем найденные продукты в локальную БД
        for product in products {
            if try await Product.query(on: req.db)
                .filter(\.$barcode == product.barcode)
                .first() == nil {
                try await product.save(on: req.db)
            }
        }
        
        return ProductSearchResponse(
            products: products,
            total: products.count,
            fromCache: false
        )
    }
    
    // GET /products/barcode/:barcode — получить продукт по штрих-коду
    func getByBarcode(req: Request) async throws -> Product {
        let user = try req.auth.require(User.self)
        
        guard let barcode = req.parameters.get("barcode") else {
            throw Abort(.badRequest, reason: "Barcode parameter is required")
        }
        
        // Сначала ищем в локальной БД
        if let product = try await Product.query(on: req.db)
            .filter(\.$barcode == barcode)
            .first() {
            return product
        }
        
        // Если нет в локальной БД, ищем через Open Food Facts API
        var offService = OpenFoodFactsService()
        if let product = try await offService.getProduct(by: barcode, on: req) {
            try await product.save(on: req.db)
            return product
        } else {
            throw Abort(.notFound, reason: "Product not found")
        }
    }
    
    // POST /products/meal — создать приём пищи из продукта
    func createMealWithProduct(req: Request) async throws -> MealResponse {
        let user = try req.auth.require(User.self)
        try MealCreateRequest.validate(content: req)
        let mealData = try req.content.decode(MealCreateRequest.self)
        
        let meal = Meal(
            userId: try user.requireID(),
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
} 