import Vapor

extension Droplet {
    public func views() throws {
        try collection(AuthController(view, drop: self))
        try collection(IndexController(view))
        try collection(PostController(view))
        try collection(AdminController(view, drop: self))
    }
}
