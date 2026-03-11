import Vapor
import Fluent

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get(":token") { req async throws -> Response in
        
        func textResponse(_ text: String, status: HTTPResponseStatus = .ok) -> Response {
            let response = Response(status: status)
            response.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
            response.body = .init(string: text)
            return response
        }

        guard let shortCode = req.parameters.get("token") else {
            return textResponse("For whatever reason, the token was missing from the URL. Sorry", status: .notFound)
        }
 
        guard let link = try? await Link.query(on: req.db)
            .filter(\.$shortCode == shortCode)
            .first() else { return textResponse("There's no link associated with that token", status: .notFound) }
        
          // handle the case where the url had a ?debug=true query parameter
        if let debug = try? req.query.get(Bool.self, at: "debug"), debug {
            let shortCodeString = "token: " + shortCode
            let redirection = "redirects to: " + link.url  
            return textResponse(shortCodeString + "\n" + redirection)
        }
        
        let ipAddress = req.remoteAddress?.ipAddress ?? "unknown"
        let userAgent = req.headers.first(name: .userAgent) ?? "unknown"
    
        Task {
            // store info in database 'Task' schedules this work on an async thread,
            // so it won't block the current request from returning the redirect response.
   
            let forward = Forward(clientIpAddress: ipAddress, userAgent: userAgent, shortCode: shortCode, otherComponents: "")
            try await forward.save(on: req.db)
        }
        
        return req.redirect(to: link.url)
    }

    try app.grouped("api").register(collection: LinksController())
}
