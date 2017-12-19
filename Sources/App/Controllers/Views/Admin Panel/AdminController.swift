//
//  AdminController.swift
//  App
//
//  Created by Ahmed Raad on 10/24/17.
//

import Foundation
import Vapor

final class AdminController: RouteCollection {
    
    let view: ViewRenderer
    let dropLet: Droplet
    init(_ view: ViewRenderer, drop: Droplet) {
        self.view = view
        self.dropLet = drop
    }
    
    func build(_ builder: RouteBuilder) throws {
        builder.frontend(.admin).group("dashboard") { dashboard in
            dashboard.get(handler: index)
            dashboard.group("posts", handler: { post in
                post.get(handler: posts)
                post.get(Post.parameter, handler: getPost)
                post.post("update", Post.parameter, handler: updatePost)
                post.get("accept", Post.parameter, handler: acceptPost)
                post.get("reject", Post.parameter, handler: rejectPost)
                post.get("remove", Post.parameter, handler: removePost)
            })
            
            dashboard.group("users", handler: { user in
                user.get(handler: allUsers)
                user.get(User.parameter, handler: getUser)
                user.post("update", User.parameter, handler: updateUser)
                user.get("ban", User.parameter, handler: banUser)
                user.get("unban", User.parameter, handler: unbanUser)
                
            })
            
            dashboard.group("categories", handler: { category in
                category.get(handler: allCategories)
                category.post("add", handler: addCategory)
                category.get("remove", Category.parameter, handler: removeCategory)
            })
        }
    }
    
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        do {
            let posts = try Post.makeQuery().limit(5)
            let sorted = try posts.all().sorted(by: { (post, _) -> Bool in
                return try post.likes() > post.likes()
            })
            data["posts_count"] = try Post.all().count
            data["users_count"] = try User.all().count
            data["likes_count"] = try Like.makeQuery().filter("type", true).all().count
            data["dislikes_count"] = try Like.makeQuery().filter("type", false).all().count
            data["trends"] = try sorted.publicRow()
            return try view.make("admin/index", data)
        } catch {
            return Response(redirect: "/")
        }
    }
    
    /* Posts Requests */
    
    func posts(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        do {
            let posts = try Post.makeQuery().sort("created_at", .descending).paginator(20, request: req)
            data["posts"] = try posts.makeNode(in: nil)
            return try view.make("admin/posts", data)
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func getPost(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        do {
            let post = try req.parameters.next(Post.self)
            data["categories"] = try Category.all().publicRow()
            data["post"] = try post.publicRow()
            return try view.make("admin/post", data)
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func updatePost(_ req: Request) throws -> ResponseRepresentable {
        let post = try req.parameters.next(Post.self)
        guard let title = req.data["title"]?.string, let content = req.data["content"]?.string, let category = req.data["category"]?.int else {
            return Response(redirect: "/dashboard")
        }
        do {
            post.title = title
            post.content = content
            post.category_id = Identifier(category)
            try post.save()
            let id = post.id?.int ?? 0
            return Response(redirect: "/dashboard/posts/\(id)").flash(.success, "post updated successfully")
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func acceptPost(_ req: Request) throws -> ResponseRepresentable {
        do {
            let post = try req.parameters.next(Post.self)
            post.isPublished = true
            try post.save()
            let post_id = post.id?.int ?? 0
            try sendEmail(.accept, content: "\(post_id)", to: post.author.get()!.email, drop: self.dropLet)
            return Response(redirect: "/dashboard/posts").flash(.success, "Post Accepted Successfully")
        } catch {
            return Response(redirect: "/dashboard/posts")
        }
    }
    
    func rejectPost(_ req: Request) throws -> ResponseRepresentable {
        do {
            let post = try req.parameters.next(Post.self)
            let post_id = post.id?.int ?? 0
            try sendEmail(.reject, content: "\(post_id)", to: post.author.get()!.email, drop: self.dropLet)
            try post.delete()
            return Response(redirect: "/dashboard/posts").flash(.success, "Post Rejected Successfully")
        } catch {
            return Response(redirect: "/dashboard/posts")
        }
    }
    
    func removePost(_ req: Request) throws -> ResponseRepresentable {
        do {
            let post = try req.parameters.next(Post.self)
            let likes = try Like.makeQuery().filter("post_id", post.id)
            try likes.delete()
            try post.delete()
            return Response(redirect: "/dashboard/posts").flash(.success, "Post Removed Successfully")
        } catch {
            return Response(redirect: "/dashboard/posts")
        }
    }
    
    
    /* Users Requests */
    
    func allUsers(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        do {
            let users = try User.makeQuery().sort("created_at", .descending).paginator(20, request: req)
            data["users"] = try users.makeNode(in: nil)
            return try view.make("admin/users", data)
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func getUser(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        do {
            let user = try req.parameters.next(User.self)
            data["user"] = try user.publicRow()
            return try view.make("admin/user", data)
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func updateUser(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        let user = try req.parameters.next(User.self)
        let id = user.id?.int ?? 0
        guard let name = req.data["name"]?.string else {
            return Response(redirect: "/dashboard/users/\(id)")
        }
        do {
            user.name = name
//            user.admin = admin
            try user.save()
            data["user"] = try user.publicRow()
            return Response(redirect: "/dashboard/users/\(id)").flash(.success, "user editied successfully")
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func banUser(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.parameters.next(User.self)
        do {
            user.isBanned = true
            try user.save()
            return Response(redirect: "/dashboard/users").flash(.success, "user banned successfully")
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func unbanUser(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.parameters.next(User.self)
        do {
            user.isBanned = false
            try user.save()
            return Response(redirect: "/dashboard/users").flash(.success, "user unbanned successfully")
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    /* Categories Requests */
    
    func allCategories(_ req: Request) throws -> ResponseRepresentable {
        var data: [String: Any] = [:]
        do {
            let users = try Category.all()
            data["categories"] = try users.publicRow()
            return try view.make("admin/categories", data)
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func addCategory(_ req: Request) throws -> ResponseRepresentable {
        guard let name = req.data["category_name"]?.string, let icon = req.data["category_icon"]?.string else {
            return Response(redirect: "/dashboard/categories").flash(.error, "missing data")
        }
        do {
            let category = Category(name: name, icon: icon)
            try category.save()
            return Response(redirect: "/dashboard/categories").flash(.success, "Category added successfully")
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
    func removeCategory(_ req: Request) throws -> ResponseRepresentable {
        let category = try req.parameters.next(Category.self)
        do {
            try category.delete()
            return Response(redirect: "/dashboard/categories").flash(.success, "Category deleted successfully")
        } catch {
            return Response(redirect: "/dashboard")
        }
    }
    
}
