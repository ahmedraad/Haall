//
//  Category.swift
//  App
//
//  Created by Ahmed Raad on 10/13/17.
//

import Foundation
import Vapor
import FluentProvider

final class Category: Model {
    
    var storage = Storage()
    
    var name: String
    var icon: String
    
    init(name: String, icon: String) {
        self.name = name
        self.icon = icon
    }
    
    init(row: Row) throws {
        self.name = try row.get(Field.name)
        self.icon = try row.get(Field.icon)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Field.id, id)
        try row.set(Field.name, name)
        try row.set(Field.icon, icon)
        return row
    }
}

extension Array where Element : Category {
    
    func publicRow() throws -> Row {
        var result: [Row] = []
        for value in self {
            try result.append(value.publicRow())
        }
        return Row(result)
    }
}

extension Category {
    func publicRow() throws -> Row {
        var row = Row()
        try row.set(Field.id, id)
        try row.set(Field.name, name)
        try row.set("posts_count", posts().all().count)
        try row.set(Field.icon, icon)
        return row
    }
}


extension Category: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { db in
            db.id()
            db.string(Field.name)
            db.string(Field.icon)
        })
    }
    
    static func revert(_ database: Database) throws {
        
    }
}

extension Category {
    
    func posts() throws -> Query<Post> {
        guard let id = self.id else { throw Abort.badRequest }
        return try Post.makeQuery().filter("category_id", id)
    }
    
    enum Field: String {
        case id
        case name
        case icon
    }
}
