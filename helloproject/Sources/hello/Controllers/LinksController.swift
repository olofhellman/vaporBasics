import Fluent
import Vapor

//     Create is the C in CRUD
struct CreateLinkRequest: Content {
    let url: String
    let shortCode: String
}

//     Update is the U in CRUD
struct UpdateLinkRequest: Content {
    let url: String
    let shortCode: String
}

//      Read is the R in CRUD
// When Reading from the database with a GET,  LinkResponse is what gets returned 
struct LinkResponse: Content {
    let id: UUID?
    let url: String
    let shortCode: String

    init(from link: Link) {
        self.id = link.id
        self.url = link.url
        self.shortCode = link.shortCode
    }
}

// LinksController is registered in routes.swift under the partial path "api" 
struct LinksController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let links = routes.grouped("links")
        // Now, links handles all requests to /api/links 

        // register a handler for GET /api/links
        links.get(use: handleGET)

        // register a handler for POST /api/links
        links.post(use: handlePOST)

        // now, register handlers for the subpaths /api/links/:linkID
        links.group(":linkID") { link in

            // GET a single link
            link.get(use: handleGETLinkID)

            // PUT an Update for a single link
            link.put(use: handlePUTUpdate)

            // DELETE a single link
            link.delete(use: handleDELETE)
        }
    }

    func handleGET(req: Request) async throws -> [LinkResponse] {
        let links = try await Link.query(on: req.db).all()
        return links.map { LinkResponse(from: $0) }
    }

    func handlePOST(req: Request) async throws -> Response {
        let payload: CreateLinkRequest = try req.content.decode(CreateLinkRequest.self)
        try validateInput(url: payload.url, shortCode: payload.shortCode)

        let existing = try await Link.query(on: req.db)
            .filter(\.$shortCode == payload.shortCode)
            .first()

        guard existing == nil else {
            throw Abort(.conflict, reason: "shortCode already exists")
        }

        let link = Link(url: payload.url, shortCode: payload.shortCode)
        try await link.save(on: req.db)

        let response = Response(status: .created)
        try response.content.encode(LinkResponse(from: link))
        return response
    }

    func handleGETLinkID(req: Request) async throws -> LinkResponse {
        let link = try await findLink(req)
        return LinkResponse(from: link)
    }

    func handlePUTUpdate(req: Request) async throws -> LinkResponse {
        let link = try await findLink(req)
        let payload = try req.content.decode(UpdateLinkRequest.self)
        try validateInput(url: payload.url, shortCode: payload.shortCode)

        let duplicate = try await Link.query(on: req.db)
            .filter(\.$shortCode == payload.shortCode)
            .filter(\.$id != link.requireID())
            .first()

        guard duplicate == nil else {
            throw Abort(.conflict, reason: "shortCode already exists")
        }

        link.url = payload.url
        link.shortCode = payload.shortCode
        try await link.save(on: req.db)

        return LinkResponse(from: link)
    }

    func handleDELETE(req: Request) async throws -> HTTPStatus {
        let link = try await findLink(req)
        try await link.delete(on: req.db)
        return .noContent
    }

    private func findLink(_ req: Request) async throws -> Link {
        guard let link = try await Link.find(req.parameters.get("linkID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return link
    }

    private func validateInput(url: String, shortCode: String) throws {
        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "url is required")
        }

        guard !shortCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "shortCode is required")
        }
    }
}
