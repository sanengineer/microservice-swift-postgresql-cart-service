import Fluent
import FluentSQL

struct CreateCartSchema: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("carts")
            .id()
            .field("user_id", .uuid, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("carts").delete()
    }    
}