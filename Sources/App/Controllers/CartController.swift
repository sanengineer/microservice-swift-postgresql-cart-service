import Vapor
import Fluent


struct CartController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userAuthMiddleware = UserAuthMiddleware()
        let userAuthByUserIdMiddleware = UserAuthMiddlewareByUserId()
        let midUserAuthMiddleware = MidUserAuthMiddleware()
        let cartRoute = router.grouped("cart")
        let cartRoutesAuthUser = cartRoute.grouped(userAuthMiddleware)
        let cartRoutesAuthByUserId = cartRouteByUserId.grouped(userAuthByUserIdMiddleware)
        let cartRoutesAuthMidUser = cartRoute.grouped(MidUserAuthMiddleware)

        cartRoutesAuthMidUser.get(use: getAllHandler)

        cartRoutesAuthUser.post(use: createHandler)
        cartRoutesAuthByUserId.get(":user_id", use: getHandlerByUserId)
        cartRoutesAuthByUserId.get(":user_id", ":cart_id", use: getHandlerByCartId)
        cartRoutesAuthByUserId.delete(":cart_id", use: deleteHandler)
    }
    
    func createHandler(_ req: Request) throws -> Future<Cart> {
        return try req.content.decode(Cart.self).flatMap { cart in
            return cart.save(on: req)
        }
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Cart]> {
        return Cart.query(on: req).all()
    }
    
    func getOneHandlerByUserId(_ req: Request) throws -> EventLoopFuture<[Cart]> { 
        guard let params = req.parameters.get("user_id", as: UUID.self)  else {
            throw Abort(.badRequest)
        }

        return Cart.query(on: req.db).filter(\.$user_id == params).all()
    }

    func getOneHandlerByOrderId(_ req: Request) throws -> EventLoopFuture<Cart> { 
        return Cart.find(req.parameters.get("cart_id") ,on: req.db).unwrap(or: Abort(.notFound))
    }
    
    func deleteOneHandlerByOrderId(_ req: Request) throws -> EventLoopFuture<Response> { 
        guard let params = req.parameters.get("cart_id", as: UUID.self)  else {
            throw Abort(.badRequest)
        }

        return Order.query(on: req.db).filter(\.$id == params).delete().flatMap {
            return req.eventLoop.makeSucceededFuture(Response(status: .accepted, body: "Cart deleted"))
        }
    }
}