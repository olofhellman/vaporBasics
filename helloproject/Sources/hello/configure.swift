import Vapor
import Fluent
import FluentSQLiteDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure SQLite for app data and use an in-memory DB in tests.
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }

    // Create Links/Forwards schemas.
    app.migrations.add(LinksDatabaseMigration())
    app.migrations.add(SeedLinks())
    app.migrations.add(ForwardsDatabaseMigration())
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
