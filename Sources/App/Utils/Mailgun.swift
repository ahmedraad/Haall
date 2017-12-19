//
//  Mailgun.swift
//  App
//
//  Created by Ahmed Raad on 10/23/17.
//

import HTTP
import SMTP
import URI
import FormData
import Multipart
import Vapor

// MARK: Mailgun
public final class Mailgun: MailProtocol {
    public let clientFactory: ClientFactoryProtocol
    public let apiURI: URI
    public let apiKey: String
    public let domain: String
    
    public init(
        domain: String,
        apiKey: String,
        _ clientFactory: ClientFactoryProtocol
        ) throws {
        self.apiURI = try URI("https://api.mailgun.net/v3/")
        self.clientFactory = clientFactory
        self.apiKey = apiKey
        self.domain = domain
    }
}

// MARK: Sending Emails
extension Mailgun {
    public func send(_ emails: [Email]) throws {
        try emails.forEach(_send)
    }
    
    private func _send(_ mail: Email) throws {
        let uri = apiURI.appendingPathComponent(domain).appendingPathComponent("messages")
        let req = Request(method: .post, uri: uri)
        
        let basic = "api:\(apiKey)".makeBytes().base64Encoded.makeString()
        req.headers["Authorization"] = "Basic \(basic)"
        
        var json = JSON()
        try json.set("subject", mail.subject)
        switch mail.body.type {
        case .html:
            try json.set("html", mail.body.content)
        case .plain:
            try json.set("text", mail.body.content)
        }
        
        let fromName = mail.from.name ?? "حَل - Haall"
        let from = FormData.Field(
            name: "from",
            filename: nil,
            part: Part(
                headers: [:],
                body: "\(fromName) <\(mail.from.address)>".makeBytes()
            )
        )
        
        let to = FormData.Field(
            name: "to",
            filename: nil,
            part: Part(
                headers: [:],
                body: mail.to.map({ $0.address }).joined(separator: ", ").makeBytes()
            )
        )
        
        let subject = FormData.Field(
            name: "subject",
            filename: nil,
            part: Part(
                headers: [:],
                body: mail.subject.makeBytes()
            )
        )
        
        let bodyKey: String
        switch mail.body.type {
        case .html:
            bodyKey = "html"
        case .plain:
            bodyKey = "text"
        }
        
        let body = FormData.Field(
            name: bodyKey,
            filename: nil,
            part: Part(
                headers: [:],
                body: mail.body.content.makeBytes()
            )
        )
        
        req.formData = [
            "from": from,
            "to": to,
            "subject": subject,
            bodyKey: body
        ]
        
        let client = try clientFactory.makeClient(
            hostname: apiURI.hostname,
            port: apiURI.port ?? 443,
            securityLayer: .tls(EngineClient.defaultTLSContext())
        )
        
        let res = try client.respond(to: req)
        guard res.status.statusCode < 400 else {
            guard let json = res.json else {
                throw Abort.badRequest
            }
            throw Abort(.badRequest, metadata: json.makeNode(in: nil))
        }
    }
}

// MARK: Config
extension Mailgun: ConfigInitializable {
    public convenience init(config: Config) throws {
        guard let mailgun = config["mailgun"] else {
            throw ConfigError.missingFile("mailgun")
        }
        
        guard let domain = mailgun["domain"]?.string else {
            throw ConfigError.missing(key: ["domain"], file: "mailgun", desiredType: String.self)
        }
        
        guard let apiKey = mailgun["key"]?.string else {
            throw ConfigError.missing(key: ["key"], file: "mailgun", desiredType: String.self)
        }
        
        let client = try config.resolveClient()
        try self.init(domain: domain, apiKey: apiKey, client)
    }
}
