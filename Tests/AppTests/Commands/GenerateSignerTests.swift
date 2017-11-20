//
//  GenerateSignerTests.swift
//  vapor-jwt-template
//
//  Created by Rodrigo Kreutz on 20/11/17.
//

import XCTest
@testable import App

class GenerateSignerTests: XCTestCase {
    
    static var allTests: [(String, (GenerateSignerTests) -> () throws -> Void)] {
        return [
            ("testCommandCreation", testCommandCreation),
            ("testCommandExecutionDefaultParameters", testCommandExecutionDefaultParameters),
            ("testCommandExecutionCustomParameters", testCommandExecutionCustomParameters),
            ("testCommandExecutionInvalidParameter", testCommandExecutionInvalidParameter),
            ("testCommandExecutionInvalidParameters", testCommandExecutionInvalidParameters),
            ("testCommandExecutionInvalidAndValidParameters", testCommandExecutionInvalidAndValidParameters),
            ("testCommandExecutionUnsupportedParameters", testCommandExecutionUnsupportedParameters),
        ]
    }
    
    private var drop: Droplet!
    
    override func setUp() {
        super.setUp()
        
        var c = try! Config()
        c.environment = .test
        
        try! c.set("droplet.commands", ["gen-signer"])
        c.addConfigurable(command: GenerateSignerCommand.init, name: "gen-signer")
        
        self.drop = try! Droplet(c)
    }
    
    func testCommandCreation() {
        guard self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) != nil else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
    }
    
    func testCommandExecutionDefaultParameters() {
        guard let genCommand = self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
        
        XCTAssertNoThrow(try genCommand.run(arguments: []))
    }
    
    func testCommandExecutionCustomParameters() {
        guard let genCommand = self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
        
        XCTAssertNoThrow(try genCommand.run(arguments: ["--bits=512"]))
    }
    
    func testCommandExecutionInvalidParameter() {
        guard let genCommand = self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
        
        XCTAssertThrowsError(try genCommand.run(arguments: ["invalidParameter1"]))
    }
    
    func testCommandExecutionInvalidParameters() {
        guard let genCommand = self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
        
        XCTAssertThrowsError(try genCommand.run(arguments: ["invalidParameter1", "invalidParameter2"]))
    }
    
    func testCommandExecutionInvalidAndValidParameters() {
        guard let genCommand = self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
        
        XCTAssertThrowsError(try genCommand.run(arguments: ["invalidParameter1", "--bits=512"]))
    }
    
    func testCommandExecutionUnsupportedParameters() {
        guard let genCommand = self.drop.commands.reduce(nil, { $0 == nil ? $1 as? GenerateSignerCommand : $0 }) else {
            XCTFail("No GenerateSignerCommand found: \(self.drop.commands.map({ type(of: $0) }))")
            return
        }
        
        XCTAssertThrowsError(try genCommand.run(arguments: ["--type=rsa"]))
    }
}
