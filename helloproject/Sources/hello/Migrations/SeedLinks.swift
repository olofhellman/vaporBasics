import Fluent
import Foundation

struct SeedLinks: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let links = [
            Link(id: UUID(), url: "https://www.linkedin.com/in/olof-hellman-42a119/", shortCode: "olof"),
            Link(id: UUID(), url: "https://www.maadialna.ma", shortCode: "water"),
            Link(id: UUID(), url: "https://eitc-iota.vercel.app", shortCode: "ensias"),
            Link(id: UUID(), url: "https://mawazine.ma", shortCode: "music"),
            Link(id: UUID(), url: "https://philadelphiaeagles.com", shortCode: "football")
        ]

        for link in links {
            try await link.save(on: database)
        }
    }

    func revert(on database: any Database) async throws {
        try await Link.query(on: database)
            .filter(\.$shortCode ~~ ["olof", "water", "ensias", "music", "football"])
            .delete()
    }
}
