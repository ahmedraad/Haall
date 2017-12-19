//
//  PostController.swift
//  App
//
//  Created by Ahmed Raad on 10/13/17.
//

import Foundation
import Vapor
import Flash
import FluentProvider

final class PostController: RouteCollection {
    
    
    let view: ViewRenderer
    init(_ view: ViewRenderer) {
        self.view = view
    }
    
    func build(_ builder: RouteBuilder) throws {
        builder.frontend(.noAuthed) { noAuth in
            noAuth.get("post", Post.parameter, handler: viewPost)
        }
        
        builder.frontend { authed in
            authed.post("add", handler: add)
            authed.post("like_post", handler: likePost)
        }
        
    }

    
    func likePost(_ req: Request) throws -> ResponseRepresentable {
        var data: JSON = [:]
        guard let post_id = req.data["post_id"]?.int else {
            return try JSON(node: ["error": true, "msg": "missing post id"])
        }
        
        guard let type = req.data["status"]?.bool else {
            return try JSON(node: ["error": true, "msg": "missing status"])
        }
        
        do {
            guard let post = try Post.find(post_id) else {
                return try JSON(node: ["error": true, "msg": "post not found"])
            }
            
            let postLike = try Like.makeQuery().filter("post_id", post.id).filter("user_id", req.user().id).first()
            
            if postLike == nil {
                if type {
                    let newLike = try Like(post_id: post.id, user_id: req.user().id, type: true)
                    try newLike.save()
                    data["data"] = try JSON(node: ["status": true])
                } else {
                    let newLike = try Like(post_id: post.id, user_id: req.user().id, type: false)
                    try newLike.save()
                    data["data"] = try JSON(node: ["status": false])
                }
            } else {
                if postLike!.type && type {
                    try postLike?.delete()
                } else if postLike!.type && type == false {
                    postLike?.type = false
                    try postLike?.save()
                    data["data"] = try JSON(node: ["status": false])
                } else if postLike!.type == false && type {
                    postLike?.type = true
                    try postLike?.save()
                    data["data"] = try JSON(node: ["status": true])
                } else {
                    try postLike?.delete()
                }
            }
            
            data["post_likes"] = try JSON(Like.makeQuery().filter("post_id", post.id).filter("type", true).all().count)
            data["post_dislikes"] = try JSON(Like.makeQuery().filter("post_id", post.id).filter("type", false).all().count)
            return data
        } catch {
            return try JSON(node: ["error": true])
        }
    }
    
    func add(_ req: Request) throws -> ResponseRepresentable {
        guard let title = req.data["title"]?.string, let cat_id = req.data["category_id"]?.int, let content = req.data["content"]?.string else {
            return try JSON(node: ["status": false, "msg": "الرجاء إدخال جميع المعلومات"])
        }
        
        do {
            guard let cat = try Category.find(cat_id) else {
                return try JSON(node: ["status": false, "msg": "القسم خاطئ"])
            }
            let post = Post(title: title, content: content, user_id: try req.user().id, category_id: cat.id)
            try post.save()
            return try JSON(node: ["status": true, "msg": "تم إضافة الحل بنجاح, سوف يتم مراجعته وإبلاغك"])
        } catch {
            return try JSON(node: ["status": false, "msg": "حدثت مشكلة"])
        }
    }
    
    func viewPost(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        let host = "https://haall.me"
        let post = try req.parameters.next(Post.self)
        do {
            try post.isLiked(user: req.user())
            data["user"] = try req.user().makeJSON()
            data["categories"] = try Category.all().publicRow()
            data["post"] = try post.publicRow()
            data["host"] = host
            return try view.make("singlePost", data)
        } catch {
            data["categories"] = try Category.all().publicRow()
            data["post"] = try post.publicRow()
            data["host"] = host
            return try view.make("singlePost", data)
        }
    }
}
