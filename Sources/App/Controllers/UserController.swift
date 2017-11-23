//
//  UserController.swift
//  App
//
//  Created by Rodrigo Kreutz on 16/11/17.
//

import Vapor
import HTTP
import Fluent
import Foundation
import VaporValidation
import JWTProvider
import JWT

class UserController {
    
    var droplet: Droplet
    
    init(droplet: Droplet) {
        self.droplet = droplet
    }
    
    func register(request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        let user = try User(json: json)
        
        let passwordConfirmation: String = try json.get("passwordConfirm")
        guard   try User.cryptoHasher?.make(passwordConfirmation.makeBytes()).makeString() == user.password,
                user.password != nil
            else {
                throw ValidatorError.failure(type: "password|passwordConfirm", reason: "Not confirmed or empty")
        }
        
        guard user.id?.string?.passes(EmailValidator()) == true else { throw ValidatorError.failure(type: "email", reason: "Not valid") }
        
        guard try User.makeQuery().find(user.id) == nil else {
            throw Abort.init(.badRequest, reason: "User already exists")
        }
        
        try user.save()
        return Response(status: .noContent)
    }
    
    func login(request: Request) throws -> ResponseRepresentable {
        let user = try request.user()
        let token = Token(user: user)
        
        let signers = try self.droplet.assertSigners()
        let signerKeys = signers.map({ $0.key })
        let signerKey = signerKeys[Int(arc4random()) % signerKeys.count]
        guard let signer = signers[signerKey] else { throw Abort.serverError }
        
        let jwt = try JWT(additionalHeaders: ["kid": .string(signerKey)], payload: try token.makeJSON(), signer: signer)
        
        var json = JSON()
        try json.set("token", jwt.createToken())
        return json
    }
    
    func logout(request: Request) throws -> ResponseRepresentable {
        try request.auth.unauthenticate()
        return Response(status: .noContent)
    }
    
    func me(request: Request) throws -> ResponseRepresentable {
        return try request.user()
    }
}

extension UserController: ResourceRepresentable {
    typealias Model = User
    
    func makeResource() -> Resource<User> {
        return Resource<User>(
            index: index,
            store: store,
            show: show,
            update: update,
            replace: replace,
            destroy: destroy,
            clear: clear
        )
    }
    
    private func index(request: Request) throws -> ResponseRepresentable {
        var filters: [RawOr<Filter>] = []
        
        if let query = request.query {
            if let email = query["email"]?.string?.percentDecoded {
                filters.append(Filter(User.self, .compare(User.usernameKey, .contains, .string(email))))
            }
            if let name = query["name"]?.string?.percentDecoded {
                filters.append(Filter(User.self, .compare("name", .contains, .string(name))))
            }
        }
        
        return try User.makeQuery().filter(Filter(User.self, .group(.and, filters))).all().makeJSON()
    }
    
    private func store(request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        
        let user = try User(json: json)
        
        guard user.id?.string?.passes(EmailValidator()) == true else { throw ValidatorError.failure(type: "email", reason: "Not valid") }
        
        let password: String = try json.get("password")
        user.password = try self.droplet.hash.make(password.makeBytes()).makeString()
        
        guard try User.makeQuery().find(user.id) == nil else {
            throw Abort(.conflict)
        }
        
        try user.save()
        return user
    }
    
    private func show(request: Request, user: User) throws -> ResponseRepresentable {
        return user
    }
    
    private func update(request: Request, user: User) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        if let name = json["name"]?.string {
            user.name = name
        }
        if let password = json["password"]?.string {
            user.password = try self.droplet.hash.make(password.makeBytes()).makeString()
        }
        try user.save()
        return user
    }
    
    private func replace(request: Request, user: User) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        let newUser = try User(json: json)
        
        guard newUser.id?.string?.passes(EmailValidator()) == true else { throw ValidatorError.failure(type: "email", reason: "Not valid") }
        
        newUser.id = user.id
        try user.delete()
        try newUser.save()
        return newUser
    }
    
    private func destroy(request: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return Response(status: .noContent)
    }
    
    private func clear(request: Request) throws -> ResponseRepresentable {
        try User.makeQuery().delete()
        return Response(status: .noContent)
    }
}
