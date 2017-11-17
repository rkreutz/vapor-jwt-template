//
//  Token.swift
//  App
//
//  Created by Rodrigo Kreutz on 16/11/17.
//

import Foundation
import JWT

enum Audience: String {
    case user
    case admin
}

struct Token {
    
    let subjectId: String
    let audience: String
    let issueDate: Date
    
    init(subjectId: String, audience: String, issueDate: Date) {
        self.subjectId = subjectId
        self.audience = audience
        self.issueDate = issueDate
    }
    
    init(user: User) {
        self.init(subjectId: user.id?.string ?? "", audience: Audience.user.rawValue, issueDate: Date())
    }
}

extension Token: JSONConvertible {
    
    init(json: JSON) throws {
        self.subjectId = try json.get(SubjectClaim.name)
        self.audience = try json.get(AudienceClaim.name)
        self.issueDate = Date(timeIntervalSince1970: try json.get(ExpirationTimeClaim.name))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(SubjectClaim.name, self.subjectId)
        try json.set(AudienceClaim.name, self.audience)
        try json.set(ExpirationTimeClaim.name, self.issueDate.timeIntervalSince1970)
        return json
    }
}
