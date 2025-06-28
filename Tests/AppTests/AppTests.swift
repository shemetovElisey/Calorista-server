import XCTVapor
import Fluent
@testable import App

// MARK: - Test Data Structures

struct TestUserData: Content {
    let email: String
    let password: String
    let name: String
}

struct TestLoginData: Content {
    let email: String
    let password: String
}

struct TestMealData: Content {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: String
}

struct TestProductMealData: Content {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: String
}

struct TestInvalidMealData: Content {
    let name: String
}

struct AuthResponse: Codable {
    let token: String
    let user: UserResponse
}

struct ProductSearchResponse: Codable {
    let products: [Product]?
    let total: Int?
    let page: Int?
    let pageSize: Int?
}

final class AppTests: XCTestCase {
    var app: Application!
    var testCounter = 0
    
    override func setUpWithError() throws {
        app = try Application(.testing)
        try configure(app)
        
        // Очищаем базу данных перед каждым тестом
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    // MARK: - Helper Methods
    
    private func getUniqueEmail() -> String {
        testCounter += 1
        return "test\(testCounter)@example.com"
    }
    
    private func registerUser() throws -> (token: String, user: UserResponse) {
        let userData = TestUserData(
            email: getUniqueEmail(),
            password: "password123",
            name: "Test User"
        )
        
        var token: String = ""
        var user: UserResponse = UserResponse(id: UUID(), email: "", name: "", createdAt: nil)
        
        try app.test(.POST, "/auth/register", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let authResponse = try response.content.decode(AuthResponse.self)
            token = authResponse.token
            user = authResponse.user
        })
        
        return (token, user)
    }
    
    // MARK: - Authentication Tests
    
    func testUserRegistration() throws {
        let userData = TestUserData(
            email: getUniqueEmail(),
            password: "password123",
            name: "Test User"
        )
        
        try app.test(.POST, "/auth/register", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let authResponse = try response.content.decode(AuthResponse.self)
            XCTAssertNotNil(authResponse.token)
            XCTAssertEqual(authResponse.user.email, userData.email)
            XCTAssertEqual(authResponse.user.name, userData.name)
            XCTAssertNotNil(authResponse.user.id)
        })
    }
    
    func testUserRegistrationWithoutAPIKey() throws {
        let userData = TestUserData(
            email: getUniqueEmail(),
            password: "password123",
            name: "Test User"
        )
        
        try app.test(.POST, "/auth/register", beforeRequest: { req in
            try req.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
    
    func testUserRegistrationDuplicateEmail() throws {
        let email = getUniqueEmail()
        
        // First registration
        let userData = TestUserData(
            email: email,
            password: "password123",
            name: "Test User"
        )
        
        try app.test(.POST, "/auth/register", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Second registration with same email
        try app.test(.POST, "/auth/register", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .conflict)
        })
    }
    
    func testUserLogin() throws {
        let email = getUniqueEmail()
        
        // First register a user
        let userData = TestUserData(
            email: email,
            password: "password123",
            name: "Test User"
        )
        
        try app.test(.POST, "/auth/register", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(userData)
        })
        
        // Then login
        let loginData = TestLoginData(
            email: email,
            password: "password123"
        )
        
        try app.test(.POST, "/auth/login", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(loginData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let authResponse = try response.content.decode(AuthResponse.self)
            XCTAssertNotNil(authResponse.token)
            XCTAssertEqual(authResponse.user.email, email)
        })
    }
    
    func testUserLoginInvalidCredentials() throws {
        let loginData = TestLoginData(
            email: "nonexistent@example.com",
            password: "wrongpassword"
        )
        
        try app.test(.POST, "/auth/login", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(loginData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }
    
    func testGetUserProfile() throws {
        let (token, user) = try registerUser()
        
        // Get user profile
        try app.test(.GET, "/auth/me", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let userProfile = try response.content.decode(UserResponse.self)
            XCTAssertEqual(userProfile.email, user.email)
            XCTAssertEqual(userProfile.name, user.name)
        })
    }
    
    func testGetUserProfileWithoutToken() throws {
        try app.test(.GET, "/auth/me", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
    
    // MARK: - Meal Tests
    
    func testCreateMeal() throws {
        let (token, _) = try registerUser()
        
        // Create meal
        let mealData = TestMealData(
            name: "Завтрак",
            calories: 350,
            protein: 15.5,
            carbs: 45.2,
            fat: 12.8,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(mealData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let meal = try response.content.decode(MealResponse.self)
            XCTAssertEqual(meal.name, "Завтрак")
            XCTAssertEqual(meal.calories, 350)
            XCTAssertEqual(meal.protein, 15.5)
            XCTAssertEqual(meal.carbs, 45.2)
            XCTAssertEqual(meal.fat, 12.8)
            XCTAssertNotNil(meal.id)
        })
    }
    
    func testCreateMealWithoutAuth() throws {
        let mealData = TestMealData(
            name: "Завтрак",
            calories: 350,
            protein: 15.5,
            carbs: 45.2,
            fat: 12.8,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            try req.content.encode(mealData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
    
    func testGetMeals() throws {
        let (token, _) = try registerUser()
        
        // Create a meal first
        let mealData = TestMealData(
            name: "Завтрак",
            calories: 350,
            protein: 15.5,
            carbs: 45.2,
            fat: 12.8,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(mealData)
        })
        
        // Get meals
        try app.test(.GET, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let meals = try response.content.decode([MealResponse].self)
            XCTAssertEqual(meals.count, 1)
            XCTAssertEqual(meals[0].name, "Завтрак")
        })
    }
    
    func testGetMealById() throws {
        let (token, _) = try registerUser()
        var mealId: String = ""
        
        // Create a meal
        let mealData = TestMealData(
            name: "Завтрак",
            calories: 350,
            protein: 15.5,
            carbs: 45.2,
            fat: 12.8,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(mealData)
        }, afterResponse: { response in
            let meal = try response.content.decode(MealResponse.self)
            mealId = meal.id.uuidString
        })
        
        // Get meal by ID
        try app.test(.GET, "/meals/\(mealId)", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let meal = try response.content.decode(MealResponse.self)
            XCTAssertEqual(meal.name, "Завтрак")
            XCTAssertEqual(meal.id.uuidString, mealId)
        })
    }
    
    func testUpdateMeal() throws {
        let (token, _) = try registerUser()
        var mealId: String = ""
        
        // Create a meal
        let mealData = TestMealData(
            name: "Завтрак",
            calories: 350,
            protein: 15.5,
            carbs: 45.2,
            fat: 12.8,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(mealData)
        }, afterResponse: { response in
            let meal = try response.content.decode(MealResponse.self)
            mealId = meal.id.uuidString
        })
        
        // Update meal
        let updateData = TestMealData(
            name: "Обновленный завтрак",
            calories: 400,
            protein: 18.0,
            carbs: 50.0,
            fat: 15.0,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.PUT, "/meals/\(mealId)", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(updateData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let meal = try response.content.decode(MealResponse.self)
            XCTAssertEqual(meal.name, "Обновленный завтрак")
            XCTAssertEqual(meal.calories, 400)
        })
    }
    
    func testDeleteMeal() throws {
        let (token, _) = try registerUser()
        var mealId: String = ""
        
        // Create a meal
        let mealData = TestMealData(
            name: "Завтрак",
            calories: 350,
            protein: 15.5,
            carbs: 45.2,
            fat: 12.8,
            date: "2024-01-15T08:00:00Z"
        )
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(mealData)
        }, afterResponse: { response in
            let meal = try response.content.decode(MealResponse.self)
            mealId = meal.id.uuidString
        })
        
        // Delete meal
        try app.test(.DELETE, "/meals/\(mealId)", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .noContent)
        })
        
        // Verify meal is deleted
        try app.test(.GET, "/meals/\(mealId)", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }
    
    // MARK: - Product Tests
    
    func testSearchProducts() throws {
        let (token, _) = try registerUser()
        
        // Search products
        try app.test(.GET, "/products/search?query=apple", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let searchResponse = try response.content.decode(ProductSearchResponse.self)
            XCTAssertNotNil(searchResponse.products)
            // Note: This might be empty if Open Food Facts is not available
        })
    }
    
    func testSearchProductsWithoutQuery() throws {
        let (token, _) = try registerUser()
        
        // Search products without query
        try app.test(.GET, "/products/search", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }
    
    func testCreateMealFromProduct() throws {
        let (token, _) = try registerUser()
        
        // Create meal from product
        let productMealData = TestProductMealData(
            name: "Apple",
            calories: 95,
            protein: 0.5,
            carbs: 25,
            fat: 0.3,
            date: "2024-01-15T12:00:00Z"
        )
        
        try app.test(.POST, "/products/meal", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(productMealData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            
            let meal = try response.content.decode(MealResponse.self)
            XCTAssertEqual(meal.name, "Apple")
            XCTAssertEqual(meal.calories, 95)
        })
    }
    
    // MARK: - Documentation Tests
    
    func testDocumentationEndpoint() throws {
        try app.test(.GET, "/docs", afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("Calorista API Documentation"))
        })
    }
    
    // MARK: - Middleware Tests
    
    func testAPIKeyMiddleware() throws {
        // Test without API key
        try app.test(.GET, "/auth/me", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        
        // Test with wrong API key
        try app.test(.GET, "/auth/me", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "wrong-key")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        
        // Test with correct API key but no auth token
        try app.test(.GET, "/auth/me", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
    
    func testAuthMiddleware() throws {
        let (token, _) = try registerUser()
        
        // Test with invalid token
        try app.test(.GET, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer invalid-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        
        // Test with valid token
        try app.test(.GET, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidMealId() throws {
        let (token, _) = try registerUser()
        
        // Test with invalid UUID
        try app.test(.GET, "/meals/invalid-uuid", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        
        // Test with non-existent UUID
        try app.test(.GET, "/meals/123e4567-e89b-12d3-a456-426614174000", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }
    
    func testValidationErrors() throws {
        let (token, _) = try registerUser()
        
        // Test meal creation with missing required fields
        let invalidMealData = TestInvalidMealData(name: "Завтрак")
        
        try app.test(.POST, "/meals", beforeRequest: { req in
            req.headers.add(name: "X-API-Key", value: "default-secret-key-2024")
            req.headers.add(name: "Authorization", value: "Bearer \(token)")
            try req.content.encode(invalidMealData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }
} 