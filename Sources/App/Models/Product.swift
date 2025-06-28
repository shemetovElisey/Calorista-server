import Vapor
import Fluent

// Модель продукта из Open Food Facts
final class Product: Model, Content {
    static let schema = "products"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "barcode")
    var barcode: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "brand")
    var brand: String?
    
    @Field(key: "calories_per_100g")
    var caloriesPer100g: Double?
    
    @Field(key: "protein_per_100g")
    var proteinPer100g: Double?
    
    @Field(key: "fat_per_100g")
    var fatPer100g: Double?
    
    @Field(key: "carbohydrates_per_100g")
    var carbohydratesPer100g: Double?
    
    @Field(key: "category")
    var category: String?
    
    @Field(key: "image_url")
    var imageUrl: String?
    
    @Field(key: "last_updated")
    var lastUpdated: Date
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, barcode: String, name: String, brand: String? = nil, caloriesPer100g: Double? = nil, proteinPer100g: Double? = nil, fatPer100g: Double? = nil, carbohydratesPer100g: Double? = nil, category: String? = nil, imageUrl: String? = nil) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbohydratesPer100g = carbohydratesPer100g
        self.category = category
        self.imageUrl = imageUrl
        self.lastUpdated = Date()
    }
}

// DTO для поиска продуктов
struct ProductSearchRequest: Content {
    let query: String
}

struct ProductSearchResponse: Content {
    let products: [Product]
    let total: Int
    let fromCache: Bool
}

// DTO для создания приёма пищи с продуктом
struct MealWithProductDTO: Content {
    let productBarcode: String
    let quantity: Double // в граммах
    let date: Date?
}

extension MealWithProductDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("productBarcode", as: String.self, is: !.empty, required: true)
        validations.add("quantity", as: Double.self, is: .range(0.01...), required: true)
    }
} 