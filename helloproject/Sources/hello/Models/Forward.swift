import Fluent
import Vapor

final class Forward: Model, Content, @unchecked Sendable {
    static let schema = "forwards"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "client_ipaddress")
    var clientIpAddress: String

    @Field(key: "user_agent")
    var userAgent: String

    @Field(key: "short_code")
    var shortCode: String

    @Field(key: "other_components")
    var otherComponents: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        clientIpAddress: String,
        userAgent: String,
        shortCode: String,
        otherComponents: String
    ) {
        self.id = id
        self.clientIpAddress = clientIpAddress
        self.userAgent = userAgent
        self.shortCode = shortCode
        self.otherComponents = otherComponents
        self.createdAt = Date()
    }
}
