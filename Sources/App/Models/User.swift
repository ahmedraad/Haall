import Vapor
import FluentProvider
import AuthProvider
import Validation
import Foundation

final class User: Model {
    
    var storage = Storage()
    
    var name: String
    var email: String
    var password: String
    var verifyToken: String
    var isVerified: Bool
    var isBanned: Bool
    var admin: Bool
    
    init(name: String, email: String, password: String, verifyToken: String, isVerified: Bool = false, admin: Bool = false, isBanned: Bool = false) throws {
        self.name = name
        self.email = try email.tested(by: EmailValidator())
        self.password = password
        self.verifyToken = verifyToken
        self.isVerified = isVerified
        self.isBanned = isBanned
        self.admin = admin
    }
    
    init(row: Row) throws {
        name = try row.get(Field.name)
        
        let email: String = try row.get(Field.email)
        self.email = try email.tested(by: EmailValidator())
        
        password = try row.get(Field.password)
        verifyToken = try row.get(Field.verify_token)
        isVerified = try row.get(Field.is_verified)
        isBanned = try row.get(Field.is_banned)
        admin = try row.get(Field.admin) ?? false
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        
        try row.set(Field.name, name)
        try row.set(Field.email, email)
        try row.set(Field.password, password)
        try row.set(Field.verify_token, verifyToken)
        try row.set(Field.is_verified, isVerified)
        try row.set(Field.is_banned, isBanned)
        try row.set(Field.admin, admin)
        
        return row
    }
    
    init(json: JSON) throws {
        name = try json.get(Field.name)
        
        let email: String = try json.get(Field.email)
        self.email = try email.tested(by: EmailValidator())
        
        password = try json.get(Field.password)
        
        verifyToken = try json.get(Field.verify_token)
        isVerified = false
        isBanned = false
        admin = try json.get(Field.admin) ?? false
    }
}

//MARK: - JSONConvertible
extension User: JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()
        
        try json.set(Field.id, id)
        try json.set(Field.name, name)
        try json.set(Field.email, email)
        try json.set(Field.admin, admin)
        try json.set(User.createdAtKey, createdAt)
        try json.set(User.updatedAtKey, updatedAt)
        try json.set("token", try token()?.token)
        
        return json
    }
}

extension User: NodeConvertible {
    convenience init(node: Node) throws {
        try self.init(
            name: node.get(Field.name),
            email: node.get(Field.email),
            password: node.get(Field.password),
            verifyToken: node.get(Field.verify_token),
            isVerified: node.get(Field.is_verified),
            admin: node.get(Field.admin),
            isBanned: node.get(Field.is_banned)
        )
    }
    
    func makeNode(in context: Context?) throws -> Node {
        var node = Node([:], in: context)
        try node.set(Field.id, id)
        try node.set(Field.name, name)
        try node.set(Field.email, email)
        try node.set(Field.admin, admin)
        try node.set(Field.is_verified, isVerified)
        try node.set(Field.is_banned, isBanned)
        try node.set("posts_count", posts.all().count)
        try node.set("createdAt", created_at)
        try node.set(User.updatedAtKey, updatedAt)
        return node
    }
}

extension User {
    func publicRow() throws -> Row {
        var json = Row()
        try json.set(Field.id, id)
        try json.set(Field.name, name)
        try json.set(Field.email, email)
        try json.set(Field.is_banned, isBanned)
        try json.set("posts_count", posts.all().count)
        return json
    }
}

//MARK: - Preparation
extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { builder in
            builder.id()
            builder.string(Field.name)
            builder.string(Field.email, unique: true)
            builder.string(Field.password)
            builder.string(Field.verify_token)
            builder.bool(Field.is_verified)
            builder.bool(Field.is_banned)
            builder.bool(Field.admin)
        })
    }
    
    static func revert(_ database: Database) throws {
        
    }
}

extension User: Updateable {
    public static var updateableKeys: [UpdateableKey<User>] {
        return [
            UpdateableKey(Field.verify_token.rawValue, String.self) { user, text in
                user.verifyToken = text
            }
        ]
    }
}


//MARK: - token()
extension User {
    func token() throws -> Token? {
        return try children(type: Token.self, foreignIdKey: "user_id").first()
    }
}

//MARK: - TokenAuthenticatable
extension User: TokenAuthenticatable {
    public typealias TokenType = Token
}

//MARK: - Request User Method
extension Request {
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
}

//MARK: - SessionPersistable
extension User: SessionPersistable { }

//MARK: - Timestampable
extension User: Timestampable { }

//MARK: - UserContext
struct UserContext: Context {
    var token: String
}

//MARK: - Authenticate/UnAuthenticate
extension User {
    func authenticate(req: Request) throws {
        try req.auth.authenticate(self, persist: true)
        try setSession(req: req)
    }
    
    private func setSession(req: Request) throws {
        try req.assertSession().data["user"] = self.makeJSON().makeNode(in: nil)
    }
    
    func unauthenticate(req: Request) throws {
        try req.auth.unauthenticate()
        try req.assertSession().destroy()
    }
}

//MARK: - Field
extension User {
    
    
    var likes: Children<User, Like> {
        return children()
    }
    
    var posts: Children<User, Post> {
        return children()
    }
    
    var created_at: String {
        let dateFor = DateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd || h:mm a"
        return dateFor.string(from: self.createdAt!)
    }
    
    enum Field: String {
        case id
        case name
        case email
        case password
        case verify_token
        case is_verified
        case is_banned
        case admin
    }
}
