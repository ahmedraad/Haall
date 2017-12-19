import Vapor
import HTTP

final public class AuthedMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            let user = try request.user()
            guard !user.isBanned else {
                try user.unauthenticate(req: request)
                return Response(redirect: "/").flash(.error, "لقد تم حظرك من قبل الادارة")
            }
        } catch {
            return Response(redirect: "/").flash(.error, "Please login")
        }
        return try next.respond(to: request)
    }
}


final public class AdminAuthedMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            let user = try request.user()
            guard user.admin else {
                return Response(redirect: "/").flash(.error, "Not Allowed")
            }
        } catch {
            return Response(redirect: "/").flash(.error, "Please login")
        }
        return try next.respond(to: request)
    }
}
