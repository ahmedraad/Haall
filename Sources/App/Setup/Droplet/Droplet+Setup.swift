@_exported import Vapor
import URI
import RedisProvider
import LeafProvider
import JWT

extension Droplet {
    public func setup() throws {
        if let viewRenderer = view as? LeafRenderer {
            viewRenderer.stem.register(IfValueIsLessThan())
            viewRenderer.stem.register(IfValueIsGreaterThan())
        }
        
        //Register routes and views
        try routes()
        try views()
    }
    
    func createJwtToken(_ userId: String)  throws -> String {
        guard  let sig = self.signer else {
            throw Abort.unauthorized
        }
        
        let timeToLive = 60.0 * 24 // 24 hour
        let claims:[Claim] = [
            ExpirationTimeClaim(date: Date().addingTimeInterval(timeToLive)),
            SubjectClaim(string: userId)
        ]
        
        let payload = JSON(claims)
        let jwt = try JWT(payload: payload, signer: sig)
        
        return try jwt.createToken()
    }
}
