import Fluent

// Миграция для добавления связи с пользователем в таблицу meals
struct MealUserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("meals")
            .field("user_id", .uuid, .required, .references("users", "id"))
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("meals")
            .deleteField("user_id")
            .update()
    }
} 