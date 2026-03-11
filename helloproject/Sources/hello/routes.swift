import Vapor
import Fluent

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get(":token") { req async throws -> Response in
        
        guard let shortCode = req.parameters.get("token") else {
            throw Abort(.notFound)
        }
 
        guard let link = try? await Link.query(on: req.db)
            .filter(\.$shortCode == shortCode)
            .first() else { throw Abort(.notFound) }
        
        return req.redirect(to: link.url)
    }

    try app.grouped("api").register(collection: LinksController())
}
