import Vapor
import Fluent


struct CartController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userAuthMiddleware = UserAuthMiddleware()
        let userAuthByUserIdMiddleware = UserAuthMiddlewareByUserId()
        let midUserAuthMiddleware = MidUserAuthMiddleware()
        let cartRoute = routes.grouped("cart")
        let cartRoutesAuthUser = cartRoute.grouped(userAuthMiddleware)
        let cartRoutesAuthByUserId = cartRoute.grouped(userAuthByUserIdMiddleware)
        let cartRoutesAuthMidUser = cartRoute.grouped(midUserAuthMiddleware)

        cartRoutesAuthMidUser.get(use: getAllHandler)

        cartRoutesAuthUser.post(use: createHandler)
        cartRoutesAuthByUserId.get(":user_id", use: getOneHandlerByUserId)
        cartRoutesAuthByUserId.get(":user_id", ":cart_id", use: getOneHandlerByCartId)
        cartRoutesAuthByUserId.delete(":cart_id", use: deleteOneHandlerByCartId)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Cart> {
        let cart = try req.content.decode(Cart.self)
        return cart.save(on: req.db).map { cart }
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Cart]> {
        return Cart.query(on: req.db).all()
    }
    
    func getOneHandlerByUserId(_ req: Request) throws -> EventLoopFuture<[Cart]> { 
        guard let params = req.parameters.get("user_id", as: UUID.self)  else {
            throw Abort(.badRequest)
        }

        return Cart.query(on: req.db).filter(\.$user_id == params).all()
    }

    func getOneHandlerByCartId(_ req: Request) throws -> EventLoopFuture<Cart> { 
        return Cart.find(req.parameters.get("cart_id"),on: req.db).unwrap(or: Abort(.notFound))
    }
    
    func deleteOneHandlerByCartId(_ req: Request) throws -> EventLoopFuture<Response> { 
        guard let params = req.parameters.get("cart_id", as: UUID.self)  else {
            throw Abort(.badRequest)
        }

        return Cart.query(on: req.db).filter(\.$id == params).delete().flatMap {
            return req.eventLoop.makeSucceededFuture(Response(status: .accepted, body: "Cart deleted"))
        }
    }
}