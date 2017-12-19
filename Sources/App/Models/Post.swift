//
//  Post.swift
//  App
//
//  Created by Ahmed Raad on 10/13/17.
//

import Foundation
import FluentProvider
import AnyDate

final class Post: Model {
    
    var storage = Storage()
    
    var title: String
    var content: String
    var user_id: Identifier?
    var category_id: Identifier?
    var isPublished: Bool = false
    var isLikedPost: Int = 0
    
    init(title: String, content: String, user_id: Identifier?, category_id: Identifier?) {
        self.title = title
        self.content = content
        self.user_id = user_id
        self.category_id = category_id
    }
    
    init(row: Row) throws {
        self.title = try row.get(Field.title)
        self.content = try row.get(Field.content)
        self.user_id = try row.get(Field.user_id)
        self.isPublished = try row.get(Field.is_published)
        self.category_id = try row.get(Field.category_id)

    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Field.title, title)
        try row.set(Field.content, content)
        try row.set(Field.user_id, user_id)
        try row.set(Field.category_id, category_id)
        try row.set(Field.is_published, isPublished)
        return row
    }
}

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { db in
            db.id()
            db.string(Field.title)
            db.text(Field.content.rawValue)
            db.bool(Field.is_published)
            db.parent(User.self, optional: false, foreignIdKey: Field.user_id.rawValue)
            db.parent(Category.self, optional: false, foreignIdKey: Field.category_id.rawValue)
        })
    }
    
    static func revert(_ database: Database) throws {
        
    }
}

extension Post: Timestampable {}

extension Array where Element : Post {
    
    func publicRow() throws -> Row {
        var result: [Row] = []
        for value in self {
            try result.append(value.publicRow())
        }
        return Row(result)
    }
}

extension Post: NodeConvertible {
    convenience init(node: Node) throws {
        try self.init(
            title: node.get(Field.title),
            content: node.get(Field.content),
            user_id: node.get(Field.user_id),
            category_id: node.get(Field.category_id)
        )
    }
    
    func makeNode(in context: Context?) throws -> Node {
        var node = Node([:], in: context)
        try node.set(Field.id, id)
        try node.set(Field.title, title)
        try node.set(Field.content, content)
        try node.set("isLiked", isLikedPost)
        try node.set("isNew", isNew)
        try node.set(Field.likes, likes())
        try node.set(Field.is_published, isPublished)
        try node.set(Field.unlikes, unLikes())
        try node.set("author", author.get()?.makeJSON())
        try node.set("category", category.get()?.makeRow())
        try node.set("createdAt", created_at)
        try node.set("updatedAt", updatedAt)
        return node
    }
}

extension Post {
    
    func publicRow() throws -> Row {
        var row = Row()
        try row.set(Field.id, id)
        try row.set(Field.title, title)
        try row.set(Field.content, content)
        try row.set("isLiked", isLikedPost)
        try row.set("isNew", isNew)
        try row.set(Field.likes, likes())
        try row.set(Field.unlikes, unLikes())
        try row.set("author", author.get()?.makeJSON())
        try row.set("category", category.get()?.makeRow())
        try row.set("createdAt", created_at)
        try row.set("updatedAt", updatedAt)
        return row
    }
    
    var author: Parent<Post,User> {
        return parent(id: user_id)
    }
    
    var category: Parent<Post,Category> {
        return parent(id: category_id)
    }

    var created_at: String {
        let dateFor = DateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd || h:mm a"
        return dateFor.string(from: self.createdAt!)
    }
    
    var isNew: Bool {
        return NSCalendar.current.isDateInToday(createdAt!)
    }
    
    func likes() throws -> Int {
        let allLikes = try Like.makeQuery().filter("post_id", id).all()
        return allLikes.filter { (like) -> Bool in
            return like.type == true
            }.count
    }
    
    func unLikes() throws -> Int {
        let allUnLikes = try Like.makeQuery().filter("post_id", id).all()
        return allUnLikes.filter { (like) -> Bool in
            return like.type == false
            }.count
    }
    
}

extension Post {
    func isLiked(user: User?) throws {
        let likes = try Like.makeQuery().filter("post_id", self.id).filter("user_id", user?.id).first()
        if likes == nil {
            isLikedPost = 0
        } else {
            isLikedPost = likes!.type ? 1 : 2
        }
    }
}

extension Post {
    
}

extension Post {
    enum Field: String {
        case id
        case title
        case content
        case user_id
        case category_id
        case is_published
        case likes
        case unlikes
    }
}
