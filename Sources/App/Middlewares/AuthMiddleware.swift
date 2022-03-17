import Vapor
import Fluent
import FluentPostgresDriver

final class UserAuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let authUrl = Environment.get("AUTH_URL") else {
            return request.eventLoop.future(error: Abort(.internalServerError))
        }
        guard let token = request.headers.bearerAuthorization else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        
        //debug
        // print("\n", "TOKEN", token, "\n")
        
         return request
            .client
            .post("\(authUrl)/user/auth/authenticate", beforeSend: {
                authRequest in
                
                //debug
                // print("\nAUTH_REQUEST: ", try authRequest.content.encode(AuthenticateData(token:token.token), as: .json))
                // print("\nAUTH_DATA: ", try authRequest.content.encode(AuthenticateData(token:token.token)), "\n")
                
                try authRequest.content.encode(AuthenticateData(token:token.token), as: .json)
            })
        
            .flatMapThrowing { response in
                let role_id = try response.content.decode(User.self).role_id
                
                if role_id == 1 || role_id == 2 || role_id == 3 {
                guard response.status == .ok  else {
                    if response.status == .unauthorized {
                        throw Abort(.unauthorized, reason: "UNAUTHORIZED")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                } else {
                    throw Abort(.unauthorized)
                }

                //debug
                //    print("\n","RESPONSE:\n", response,"\n")
                //    print("\n", "TRYYY\n", try response.content.decode(Auth.self), "\n")
                //    print("\n","ROLE_ID:", role_id,"\n")
            }
        
            .flatMap {
                return next.respond(to: request)
            }
    }
}

final class UserAuthMiddlewareByUserId: Middleware {
  
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let authUrl = Environment.get("AUTH_URL") else {
            return request.eventLoop.future(error: Abort(.internalServerError))
        }
        guard let token = request.headers.bearerAuthorization else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }

        //debug
        // print("\nBODY: \(user_id)\n")

        return request
            .client
            .post("\(authUrl)/user/auth/authenticate", beforeSend: {
                authRequest in
                try authRequest.content.encode(AuthenticateData(token:token.token), as: .json)
            }).tryFlatMap{ response -> EventLoopFuture<Response> in
                let user = try response.content.decode(User.self)
                if response.status == .ok {
                    return Cart.query(on:request.db)
                        .filter( \.$user_id == user.id)
                        .all()
                        .tryFlatMap { user -> EventLoopFuture<Response> in
                            //  print("\n","USER_TRAY_FLAT:", user.count ,"\n")
                            if user.count > 0 {
                                return next.respond(to: request)
                            } else {
                                return request.eventLoop.future(error: Abort(.unauthorized))
                            }
                        }
                } else {
                    if response.status == .unauthorized {
                        throw Abort(.unauthorized, reason: "UNAUTHORIZED")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
            }
    }
}

final class MidUserAuthMiddleware: Middleware {
  
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let authUrl = Environment.get("AUTH_URL") else {
            return request.eventLoop.future(error: Abort(.internalServerError))
        }
        guard let token = request.headers.bearerAuthorization else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }

        //debug
        // print("\n", "TOKEN", token, "\n")
        
        return request
            .client
            .post("\(authUrl)/user/auth/authenticate", beforeSend: {
                authRequest in
                try authRequest.content.encode(AuthenticateData(token:token.token), as: .json)
            })
            .flatMapThrowing { response in
               let role_id = try response.content.decode(User.self).role_id 
              
               if role_id == 1 || role_id == 2 {
                guard response.status == .ok  else {
                    if response.status == .unauthorized {
                        throw Abort(.unauthorized, reason: "UNAUTHORIZED")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }
                } else {
                    throw Abort(.unauthorized)
                }            
            }
        
            .flatMap {
                return next.respond(to: request)
            }
    }
}


