//
//  GenerateSignerCommand.swift
//  App
//
//  Created by Rodrigo Kreutz on 17/11/17.
//

import Vapor
import Console
import Foundation

final class GenerateSignerCommand: Command {
    public let id = "gen-signer"
    public let console: ConsoleProtocol
    public let fileManager: FileManager = FileManager.default
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        try arguments.forEach { (argument) in
            guard argument.hasPrefix("--"), argument.count > 2 else { throw CommandError.general("Invalid argument: \"\(argument)\"") }
            let keyValuePair = argument.suffix(from: argument.index(argument.startIndex, offsetBy: 2)).split(separator: "=")
            guard let key = keyValuePair.first, let value = keyValuePair.last, keyValuePair.count == 2 else { throw CommandError.general("Invalid argument: \"\(argument)\"") }
        }
        
        var baseUrl = try self.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        baseUrl.appendPathComponent("rsa")
        guard self.fileManager.createFile(atPath: baseUrl.path, contents: nil, attributes: nil) else { throw CommandError.general("Certificate file couldn't be created/found.") }
        print(baseUrl.path)
        let file = try FileHandle.init(forWritingTo: baseUrl)
        try console.execute(program: "openssl", arguments: ["genrsa", "512"], input: nil, output: file.fileDescriptor, error: nil)
    }
}

extension GenerateSignerCommand: ConfigInitializable {
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
}
