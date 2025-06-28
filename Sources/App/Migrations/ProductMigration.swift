import Fluent

// Миграция для создания таблицы products
struct ProductMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("products")
            .id()
            .field("barcode", .string, .required)
            .field("name", .string, .required)
            .field("brand", .string)
            .field("calories_per_100g", .double)
            .field("protein_per_100g", .double)
            .field("fat_per_100g", .double)
            .field("carbohydrates_per_100g", .double)
            .field("category", .string)
            .field("image_url", .string)
            .field("last_updated", .datetime, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "barcode")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("products").delete()
    }
} 