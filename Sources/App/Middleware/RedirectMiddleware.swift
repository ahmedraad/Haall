import Vapor
import HTTP

final public class RedirectMiddleware: Middleware {
    
    private var path: String = "/"
    
    init(path: String) {
        self.path = path
    }
    
    init() {
        
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            let user = try request.user()
            guard !user.isBanned else {
                try user.unauthenticate(req: request)
                return Response(redirect: "/").flash(.error, "لقد تم حظرك من قبل الادارة")
            }
            return Response(redirect: path)
        } catch {
            return try next.respond(to: request)
        }
    }
}
