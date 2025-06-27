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
    var calories: Double
    
    @Field(key: "carbohydrates")
    var carbohydrates: Double
    
    @Field(key: "protein")
    var protein: Double
    
    @Field(key: "fat")
    var fat: Double
    
    @Field(key: "date")
    var date: Date
    
    init() {}
    
    init(id: UUID? = nil, userId: User.IDValue, name: String, calories: Double, carbohydrates: Double, protein: Double, fat: Double, date: Date) {
        self.id = id
        self.$user.id = userId
        self.name = name
        self.calories = calories
        self.carbohydrates = carbohydrates
        self.protein = protein
        self.fat = fat
        self.date = date
    }
}

// DTO для создания нового приёма пищи с валидацией
struct MealCreateDTO: Content {
    let name: String
    let calories: Double
    let carbohydrates: Double
    let protein: Double
    let fat: Double
    let date: Date?
}

extension MealCreateDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty, required: true)
        validations.add("calories", as: Double.self, is: .range(0.01...), required: true)
        validations.add("carbohydrates", as: Double.self, is: .range(0...), required: true)
        validations.add("protein", as: Double.self, is: .range(0...), required: true)
        validations.add("fat", as: Double.self, is: .range(0...), required: true)
    }
} 