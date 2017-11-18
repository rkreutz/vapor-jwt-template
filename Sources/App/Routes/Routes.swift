import Vapor
import AuthProvider
import JWTProvider
import JWT

extension Droplet {
    private var userController: UserController {
        return UserController(droplet: self)
    }
    
    func setupRoutes() throws {
        let api = grouped("api")
        
        try setupUnauthenticatedRoutes(api)
        try setupPasswordProtectedRoutes(api)
        try setupJwtProtectedRoutes(api)
        try setupAdminRoutes(api)
    }
    
    private func setupUnauthenticatedRoutes(_ builder: RouteBuilder) throws {
        builder.get("encrypt", String.parameter) { (req) -> ResponseRepresentable in
            let toEncript = try req.parameters.next(String.self)
            var json = JSON()
            try json.set("encrypted", User.cryptoHasher?.make(toEncript.makeBytes()).makeString())
            return json
        }
        
        builder.post("register", handler: self.userController.register)
    }
    
    private func setupPasswordProtectedRoutes(_ builder: RouteBuilder) throws {
        let password = builder.grouped(PasswordAuthenticationMiddleware(User.self))
        
        password.get("login", handler: self.userController.login)
    }
    
    private func setupJwtProtectedRoutes(_ builder: RouteBuilder) throws {
        guard let signers = self.signers else { throw Abort.serverError }
        
        let jwt = builder.grouped(PayloadAuthenticationMiddleware(signers, [
                AudienceClaim(arrayLiteral: Audience.user.rawValue, Audience.admin.rawValue),
                ExpirationTimeClaim(createTimestamp: { Seconds(Date().timeIntervalSince1970) }, leeway: 5 * 60)
            ], User.self))
        
        jwt.get("me", handler: self.userController.me)
        
        jwt.get("super-secret-route") { req in
            let user = try req.user()
            let token = Token(subjectId: user.id?.string ?? "", audience: Audience.admin.rawValue, issueDate: Date())
            
            guard let signers = self.signers else { throw Abort.serverError }
            let signerKeys = signers.map({ $0.key })
            let signerKey = signerKeys[Int(arc4random()) % signerKeys.count]
            guard let signer = signers[signerKey] else { throw Abort.serverError }
            
            let jwt = try JWT(additionalHeaders: ["kid": .string(signerKey)], payload: try token.makeJSON(), signer: signer)
            
            var json = JSON()
            try json.set("token", jwt.createToken())
            return json
        }
    }
    
    private func setupAdminRoutes(_ builder: RouteBuilder) throws {
        guard let signers = self.signers else { throw Abort.serverError }
        
        let admin = builder.grouped(PayloadAuthenticationMiddleware(signers, [
                AudienceClaim(string: Audience.admin.rawValue),
                ExpirationTimeClaim(createTimestamp: { Seconds(Date().timeIntervalSince1970) }, leeway: 5 * 60)
            ], User.self))
        
        admin.resource("users", self.userController)
    }
}
