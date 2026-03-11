import Fluent
import Vapor

struct CreateLinkRequest: Content {
    let url: String
    let shortCode: String
}

struct UpdateLinkRequest: Content {
    let url: String
    let shortCode: String
}

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

struct LinksController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let links = routes.grouped("links")

        links.get(use: index)
        links.post(use: create)
        links.group(":linkID") { link in
            link.get(use: show)
            link.put(use: update)
            link.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [LinkResponse] {
        let links = try await Link.query(on: req.db).all()
        return links.map { LinkResponse(from: $0) }
    }

    func create(req: Request) async throws -> Response {
        let payload = try req.content.decode(CreateLinkRequest.self)
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

    func show(req: Request) async throws -> LinkResponse {
        let link = try await findLink(req)
        return LinkResponse(from: link)
    }

    func update(req: Request) async throws -> LinkResponse {
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

    func delete(req: Request) async throws -> HTTPStatus {
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
