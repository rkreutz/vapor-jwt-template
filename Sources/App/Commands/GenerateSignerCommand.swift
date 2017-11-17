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
        var bits = "4096"
        try arguments.forEach { (argument) in
            guard argument.hasPrefix("--"), argument.count > 2 else { throw CommandError.general("Invalid argument: \"\(argument)\"") }
            let keyValuePair = argument[argument.index(argument.startIndex, offsetBy: 2)...].split(separator: "=")
            guard let key = keyValuePair.first, let value = keyValuePair.last, keyValuePair.count == 2 else { throw CommandError.general("Invalid argument: \"\(argument)\"") }
            if key == "bits" {
                bits = String(value)
            } else {
                throw CommandError.general("Unsupported key: \(key)")
            }
        }
        
        var baseUrl = try self.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        baseUrl.appendPathComponent("tmp")
        guard self.fileManager.createFile(atPath: baseUrl.path, contents: nil, attributes: nil) else { throw CommandError.general("Certificate file couldn't be created/found.") }
        let writeHandle = try FileHandle.init(forWritingTo: baseUrl)
        let readHandle = try FileHandle.init(forReadingFrom: baseUrl)
        
        try console.execute(program: "openssl", arguments: ["genrsa", bits], input: nil, output: writeHandle.fileDescriptor, error: nil)
        
        let data = readHandle.readDataToEndOfFile()
        guard var key = String(data: data, encoding: .utf8) else { throw CommandError.general("Key generated wasn't valid") }
        key = key.replacingOccurrences(of: "\n", with: "")
        key = key.replacingOccurrences(of: "-{5}\\D{0,30}-{5}", with: "", options: .regularExpression)
        
        console.success("Add the following signer to your 'jwt.json' file:\n\"signerName\": {\n\t\"type\": \"rsa\",\n\t\"algorithm\": \"rs256\",\n\t\"key\": \"\(key)\"\n}", newLine: true)
        
        try self.fileManager.removeItem(at: baseUrl)
    }
}

extension GenerateSignerCommand: ConfigInitializable {
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
}
