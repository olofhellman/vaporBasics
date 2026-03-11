import Fluent

struct LinksDatabaseMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("links")
            .id()
            .field("url", .string, .required)
            .field("short_code", .string, .required)
            .unique(on: "short_code")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("links").delete()
    }
}
