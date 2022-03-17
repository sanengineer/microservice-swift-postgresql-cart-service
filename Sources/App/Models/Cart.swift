import Vapor
import Fluent

final class Cart: Model, Content, Codable {
    static let schema = "carts"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "user_id")
    var user_id: UUID
    
    @Timestamp(key: "created_at", on: .create)
    var created_at: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updated_at: Date?
    
    init() { }
    
    init(id: UUID? = nil, user_id: UUID, created_at: Date?, updated_at: Date?) {
        self.id = id
        self.user_id = user_id
        self.created_at = created_at
        self.updated_at = updated_at
    }
    
}