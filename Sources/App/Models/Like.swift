//
//  Like.swift
//  App
//
//  Created by Ahmed Raad on 10/15/17.
//

import Foundation
import Vapor
import FluentProvider

final class Like: Model {
    
    var storage = Storage()
    
    var post_id: Identifier?
    var user_id: Identifier?
    
    var type: Bool
    
    init(post_id: Identifier?, user_id: Identifier?, type: Bool) {
        self.post_id = post_id
        self.user_id = user_id
        self.type = type
    }
    
    init(row: Row) throws {
        post_id = try row.get(Field.post_id)
        user_id = try row.get(Field.user_id)
        type = try row.get(Field.type)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Field.id, id)
        try row.set(Field.post_id, post_id)
        try row.set(Field.user_id, user_id)
        try row.set(Field.type, type)
        return row
    }
}

extension Like: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { db in
            db.id()
            db.parent(Post.self, optional: false)
            db.parent(User.self, optional: false)
            db.bool(Field.type)
        })
    }
    
    static func revert(_ database: Database) throws {
        
    }
}

extension Array where Element : Like {
    
    func publicRow() throws -> Row {
        var result: [Row] = []
        for value in self {
            try result.append(value.publicRow())
        }
        return Row(result)
    }
}


extension Like {
    
    func publicRow() throws -> Row {
        var row = Row()
        try row.set(Field.id, id)
        try row.set(Field.post_id, post_id)
        try row.set(Field.user_id, user_id)
        try row.set(Field.type, type)
        return row
    }
    
    enum Field: String {
        case id
        case post_id
        case user_id
        case type
    }
}

