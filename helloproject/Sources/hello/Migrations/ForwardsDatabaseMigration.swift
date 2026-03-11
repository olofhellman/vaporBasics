import Fluent

struct ForwardsDatabaseMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("forwards")
            .id()
            .field("client_ipaddress", .string, .required)
            .field("user_agent", .string, .required)
            .field("short_code", .string, .required)
            .field("other_components", .string, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("forwards").delete()
    }
}
