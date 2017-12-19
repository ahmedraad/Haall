//
//  IndexController.swift
//  Run
//
//  Created by Ahmed Raad on 10/12/17.
//

import Foundation
import Vapor
import Flash
import Paginator

final class IndexController: RouteCollection {
    
    let view: ViewRenderer
    init(_ view: ViewRenderer) {
        self.view = view
    }
    
    func build(_ builder: RouteBuilder) throws {
        
        builder.frontend(.noAuthed) { (unAuthed) in
            unAuthed.get(handler: index)
            unAuthed.get("category", Category.parameter, handler: getByCategory)
            unAuthed.get("user", User.parameter, handler: postsOfUser)
        }
    }
    
    func postsOfUser(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        let host = "https://haall.me"
        let user = try req.parameters.next(User.self)
        do {
            let posts = try user.posts.makeQuery().sort("created_at", .descending).filter("is_published", true).paginator(20, request: req)
            try posts.data?.forEach({ (post) in
                try post.isLiked(user: try req.user())
            })
            data["ofUser"] = try user.publicRow()
            data["categories"] = try Category.all().publicRow()
            data["user"] = try req.user().makeJSON()
            data["posts"] = try posts.makeNode(in: nil)
            data["host"] = host
            return try view.make("user_posts", data, for: req)
        } catch {
            let posts = try user.posts.makeQuery().sort("created_at", .descending).filter("is_published", true).paginator(20, request: req)
            data["ofUser"] = try user.publicRow()
            data["categories"] = try Category.all().publicRow()
            data["posts"] = try posts.makeNode(in: nil)
            data["host"] = host
            return try view.make("user_posts", data, for: req)
        }
    }
    
    func getByCategory(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        let host = "https://haall.me"
        let category = try req.parameters.next(Category.self)
        do {
            let posts = try category.posts().filter("is_published", true).sort("created_at", .descending).paginator(20, request: req)
            try posts.data?.forEach({ (post) in
                try post.isLiked(user: try req.user())
            })
            data["current_category"] = try category.publicRow()
            data["user"] = try req.user().makeJSON()
            data["categories"] = try Category.all().publicRow()
            data["posts"] = try posts.makeNode(in: nil)
            data["host"] = host
            return try view.make("index", data, for: req)
        } catch {
            let posts = try category.posts().sort("created_at", .descending).filter("is_published", true).paginator(20, request: req)
            data["current_category"] = try category.publicRow()
            data["categories"] = try Category.all().publicRow()
            data["posts"] = try posts.makeNode(in: nil)
            data["host"] = host
            return try view.make("index", data, for: req)
        }
    }
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        let host = "https://haall.me"
        do {
            let posts = try Post.makeQuery().filter("is_published", true).sort("created_at", .descending).paginator(20, request: req)
            try posts.data?.forEach({ (post) in
                try post.isLiked(user: try req.user())
            })
            
            data["user"] = try req.user().makeJSON()
            data["categories"] = try Category.all().publicRow()
            data["posts"] = try posts.makeNode(in: nil)
            data["host"] = host
            return try view.make("index", data, for: req)
        } catch {
            let posts = try Post.makeQuery().sort("created_at", .descending).filter("is_published", true).paginator(20, request: req)
            data["categories"] = try Category.all().publicRow()
            data["posts"] = try posts.makeNode(in: nil)
            data["host"] = host
            return try view.make("index", data, for: req)
        }
    }

}
