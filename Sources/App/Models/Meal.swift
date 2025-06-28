import Vapor
import Fluent

// Модель данных для приёма пищи
final class Meal: Model, Content {
    static let schema = "meals"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "calories")
    var calories: Int
    
    @Field(key: "protein")
    var protein: Double
    
    @Field(key: "carbs")
    var carbs: Double
    
    @Field(key: "fat")
    var fat: Double
    
    @Field(key: "date")
    var date: Date
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, userId: User.IDValue, name: String, calories: Int, protein: Double, carbs: Double, fat: Double, date: Date) {
        self.id = id
        self.$user.id = userId
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
    }
}

// DTO для создания нового приёма пищи с валидацией
struct MealCreateRequest: Content {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: Date
}

struct MealResponse: Content {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: Date
    let createdAt: Date?
    let updatedAt: Date?
}

extension MealCreateRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(1...100), required: true)
        validations.add("calories", as: Int.self, is: .range(0...10000), required: true)
        validations.add("protein", as: Double.self, is: .range(0...1000), required: true)
        validations.add("carbs", as: Double.self, is: .range(0...1000), required: true)
        validations.add("fat", as: Double.self, is: .range(0...1000), required: true)
        validations.add("date", as: Date.self, required: true)
    }
}

// Расширение для конвертации Meal в MealResponse
extension Meal {
    func toResponse() -> MealResponse {
        MealResponse(
            id: self.id ?? UUID(),
            name: self.name,
            calories: self.calories,
            protein: self.protein,
            carbs: self.carbs,
            fat: self.fat,
            date: self.date,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
} 