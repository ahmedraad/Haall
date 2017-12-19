//
//  AuthController.swift
//  Run
//
//  Created by Ahmed Raad on 10/12/17.
//

import Foundation
import Vapor
import AuthProvider
import Flash
import MySQL
import HTTP
import VaporValidation
import JWT
import Crypto
import SMTP
import Sockets

final class AuthController: RouteCollection {
    
    let view: ViewRenderer
    let dropLet: Droplet
    init(_ view: ViewRenderer, drop: Droplet) {
        self.view = view
        self.dropLet = drop
    }
    
    func build(_ builder: RouteBuilder) throws {
        builder.frontend(.noAuthed) { build in
            
            build.frontend(.noAuthed).group(RedirectMiddleware()) { redirect in
                redirect.post("/login", handler: loginHandle)
                redirect.post("/register", handler: handleRegisterPost)
                redirect.get("verify", handler: verifyUser)
            }
            
            build.group(AuthedMiddleware()) { authed in
                authed.get("/logout", handler: logout)
            }
        }
        
    }
    
    func verifyUser(_ req: Request) throws -> ResponseRepresentable {
        guard let token = req.data["token"]?.string else {
            return Response(redirect: "/").flash(.error, "رابط خطأ")
        }
        do {
            guard let user = try User.makeQuery().filter("verify_token", token).first() else {
                return Response(redirect: "/").flash(.error, "رابط خطأ")
            }
            user.isVerified = true
            user.verifyToken = ""
            try user.save()
            return Response(redirect: "/").flash(.success, "تم تفعيل حسابك بنجاح, يمكنك تسجيل الدخول الآن")
        } catch {
            return Response(redirect: "/").flash(.error, "حدثت مشكلة")
        }
    }
    
    func loginHandle(_ req: Request) throws -> ResponseRepresentable {
        guard let email = req.data["email"]?.string, let password = req.data["password"]?.string else {
            return Response(redirect: "/").flash(.error, "الرجاء إدخال البريد الالكتروني و كلمة المرور")
        }
        do {
            guard let user = try User.makeQuery().filter("email", email).first() else { return Response(redirect: "/").flash(.error, "المعلومات خطاً") }
            
            if try BCryptHasher().verify(password: password, matches: user.password) {
                if user.isVerified {
                    if user.isBanned {
                        return Response(redirect: "/").flash(.error, "لقد تم حظرك من قبل الادارة")
                    } else {
                        try user.authenticate(req: req)
                    }
                    return Response(redirect: "/").flash(.success, "تم تسجيل الدخول بنجاح")
                } else {
                    return Response(redirect: "/").flash(.error, "الرجاء تأكيد حسابك")
                }
            } else {
                return Response(redirect: "/").flash(.error, "المعلومات خطاً")
            }
        } catch {
            return Response(redirect: "/").flash(.error, "حدثت مشكلة")
        }
    }
    
    func handleRegisterPost(_ req: Request) throws -> ResponseRepresentable {
        guard let data = req.formURLEncoded else { throw Abort.badRequest }
        
        //TODO: - Generic subscript upon Swift 4
        guard let password = data[User.Field.password.rawValue]?.string else { throw Abort.badRequest }
        //        guard let confirmPassword = data["confirmPassword"]?.string else { throw Abort.badRequest }
        //
        //        if password != confirmPassword {
        //            return Response(redirect: "/register").flash(.error, "Passwords don't match")
        //        }
        
        var json = JSON(node: data)
        try json.set(User.Field.password.rawValue, try BCryptHasher().make(password.bytes).makeString())
        
        let random = try Crypto.Random.bytes(count: 30).hexEncoded.makeString()
        try json.set(User.Field.verify_token, random)
        do {
            let user = try User(json: json)
            try user.save()
            try sendVerifyEmail(random, to: user.email, drop: self.dropLet)
            return Response(redirect: "/").flash(.success, "تم التسجيل بنجاح، الرجاء تأكيد حسابك عن طريق البريد الالكتروني")
        } catch is MySQLError {
            return Response(redirect: "/").flash(.error, "الحساب موجود مسبقا")
        } catch is ValidationError {
            return Response(redirect: "/").flash(.error, "Email format is invalid")
        } catch {
            return Response(redirect: "/").flash(.error, "Something went wrong")
        }
    }
    
    func logout(_ req: Request) throws -> ResponseRepresentable {
        try req.user().unauthenticate(req: req)
        return Response(redirect: "/").flash(.success, "Logged Out")
    }
}

