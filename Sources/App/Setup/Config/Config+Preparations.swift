import Vapor
import FluentProvider

extension Config {
    func setupPreparations() {
        preparations.append(User.self)
        preparations.append(Token.self)
        preparations.append(Category.self)
        preparations.append(Post.self)
        preparations.append(Like.self)
    }
}
