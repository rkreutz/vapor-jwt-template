import FluentProvider
import AuthProvider
import JWTProvider
import MongoProvider
import Crypto

extension Config {
    public func setup() throws {
        // allow fuzzy conversions for these types
        // (add your own types here)
        Node.fuzzy = [Row.self, JSON.self, Node.self]

        try setupProviders()
        try setupPreparations()
        try addConfigurables()
    }
    
    /// Configure providers
    private func setupProviders() throws {
        try addProvider(FluentProvider.Provider.self)
        try addProvider(AuthProvider.Provider.self)
        try addProvider(JWTProvider.Provider.self)
        try addProvider(MongoProvider.Provider.self)
    }
    
    /// Add all models that should have their
    /// schemas prepared before the app boots
    private func setupPreparations() throws {
        preparations.append(User.self)
    }
    
    private func addConfigurables() throws {
        self.addConfigurable(command: GenerateSignerCommand.init, name: "gen-signer")
    }
}
