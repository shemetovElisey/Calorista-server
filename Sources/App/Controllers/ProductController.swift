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
    func search(req: Request) async throws -> [Product] {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        
        guard let query = req.query[String.self, at: "query"], !query.isEmpty else {
            throw Abort(.badRequest, reason: "Query parameter is required")
        }
        
        // Сначала ищем в локальной БД
        let localProducts = try await Product.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$name ~~ query)
                group.filter(\.$brand ~~ query)
            }
            .limit(10)
            .all()
        
        if !localProducts.isEmpty {
            return localProducts
        }
        
        // Если в локальной БД нет, ищем через Open Food Facts API
        var offService = OpenFoodFactsService()
        let offProducts = try await offService.searchProducts(query: query, on: req)
        
        // Сохраняем найденные продукты в локальную БД
        for product in offProducts {
            // Проверяем, не существует ли уже продукт с таким штрих-кодом
            if try await Product.query(on: req.db)
                .filter(\.$barcode == product.barcode)
                .first() == nil {
                try await product.save(on: req.db)
            }
        }
        
        return offProducts
    }
    
    // GET /products/barcode/:barcode — получить продукт по штрих-коду
    func getByBarcode(req: Request) async throws -> Product {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        
        guard let barcode = req.parameters.get("barcode") else {
            throw Abort(.badRequest, reason: "Barcode parameter is required")
        }
        
        // Сначала ищем в локальной БД
        if let localProduct = try await Product.query(on: req.db)
            .filter(\.$barcode == barcode)
            .first() {
            return localProduct
        }
        
        // Если в локальной БД нет, запрашиваем через Open Food Facts API
        var offService = OpenFoodFactsService()
        guard let offProduct = try await offService.getProduct(by: barcode, on: req) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        
        // Сохраняем продукт в локальную БД
        try await offProduct.save(on: req.db)
        
        return offProduct
    }
    
    // POST /products/meal — создать приём пищи с продуктом
    func createMealWithProduct(req: Request) async throws -> Meal {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated")
        }
        
        try MealWithProductDTO.validate(content: req)
        let dto = try req.content.decode(MealWithProductDTO.self)
        
        // Получаем продукт (из локальной БД или API)
        let product: Product
        if let localProduct = try await Product.query(on: req.db)
            .filter(\.$barcode == dto.productBarcode)
            .first() {
            product = localProduct
        } else {
            // Если продукта нет в локальной БД, получаем через API
            var offService = OpenFoodFactsService()
            guard let offProduct = try await offService.getProduct(by: dto.productBarcode, on: req) else {
                throw Abort(.notFound, reason: "Product not found")
            }
            try await offProduct.save(on: req.db)
            product = offProduct
        }
        
        // Рассчитываем питательную ценность на основе количества
        let multiplier = dto.quantity / 100.0 // переводим в проценты от 100г
        
        let meal = Meal(
            userId: user.id!,
            name: product.name,
            calories: (product.caloriesPer100g ?? 0) * multiplier,
            carbohydrates: (product.carbohydratesPer100g ?? 0) * multiplier,
            protein: (product.proteinPer100g ?? 0) * multiplier,
            fat: (product.fatPer100g ?? 0) * multiplier,
            date: dto.date ?? Date()
        )
        
        try await meal.save(on: req.db)
        return meal
    }
} 