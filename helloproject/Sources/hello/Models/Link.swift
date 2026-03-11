import Fluent
import Vapor

final class Link: Model, Content, @unchecked Sendable {
    static let schema = "links"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "url")
    var url: String

    @Field(key: "short_code")
    var shortCode: String


    init() {}

    init(id: UUID? = nil, url: String, shortCode: String) {
        self.id = id
        self.url = url
        self.shortCode = shortCode
    }
}
