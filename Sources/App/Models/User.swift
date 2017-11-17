//
//  User.swift
//  App
//
//  Created by Rodrigo Kreutz on 16/11/17.
//

import Vapor
import FluentProvider
import AuthProvider
import HTTP
import JWTProvider
import JWT

final class User: Model {
    let storage = Storage()
    
    /// The name of the user
    var name: String
    
    /// The user's _hashed_ password
    var password: String?
    
    /// Creates a new User
    init(name: String, email: String, password: String? = nil) {
        self.name = name
        self.id = Identifier.string(email)
        if let password = password, let hashedPassword = try? User.cryptoHasher?.make(password.makeBytes()).makeString() {
            self.password = hashedPassword
        }
    }
    
    // MARK: Fluent Serialization
    
    /// Initializes the User from the
    /// database row
    init(row: Row) throws {
        name = try row.get("name")
        password = try row.get("password")
    }
    
    // Serializes the Post to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("password", password)
        return row
    }
}

// MARK: Fleunt Preparation

extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Users
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.string("password")
        }
        try database.index(["name"], for: self)
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON

// How the model converts from / to JSON.
// For example when:
//     - Creating a new User (POST /users)
//
extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            name: json.get("name"),
            email: json.get("email"),
            password: json["password"]?.string
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("name", name)
        try json.set("email", id?.string ?? "")
        return json
    }
}

// MARK: HTTP

// This allows User models to be returned
// directly in route closures
extension User: ResponseRepresentable { }

// MARK: Request

extension Request {
    /// Convenience on request for accessing
    /// this user type.
    /// Simply call `let user = try req.user()`.
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
}

// MARK: Password

// This allows the User to be authenticated
// with a password. We will use this to initially
// login the user so that we can generate a token.
private var _userCryptoHasher: CryptoHasher?

extension User: PasswordAuthenticatable {
    static var usernameKey: String { return "_id" }

    var hashedPassword: String? { return password }

    static var passwordVerifier: PasswordVerifier? { return User.cryptoHasher }
    
    static var cryptoHasher: CryptoHasher? {
        get { return _userCryptoHasher }
        set { _userCryptoHasher = newValue }
    }
}

extension User: PayloadAuthenticatable {
    typealias PayloadType = Token
    
    static func authenticate(_ payload: Token) throws -> User {
        guard let user = try User.makeQuery().find(payload.subjectId) else {
                throw AuthenticationError.invalidCredentials
        }
        
        return user
    }
}

