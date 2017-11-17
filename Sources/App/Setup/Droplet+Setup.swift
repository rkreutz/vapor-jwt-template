@_exported import Vapor

extension Droplet {
    public func setup() throws {
        try setupRoutes()
        
        User.cryptoHasher = try self.config.resolveHash() as? CryptoHasher
    }
}
