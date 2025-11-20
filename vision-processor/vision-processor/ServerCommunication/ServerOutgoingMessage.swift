nonisolated enum ServerOutgoingMessageType: String, Codable {
    case ping
    case pong
    case captureResults
}

nonisolated enum ServerOutgoingMessage: Codable {
    case ping
    case pong
    case captureResults(CaptureResults)
    
    struct CaptureResults: Codable {
        let test: String
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case test
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ServerOutgoingMessageType.self, forKey: .type)
        
        switch type {
        case .ping:
            self = .ping
        case .pong:
            self = .pong
        case .captureResults:
            self = .captureResults(try CaptureResults(from: decoder))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        switch self {
        case .ping:
            try container.encode(ServerOutgoingMessageType.ping, forKey: .type)
        case .pong:
            try container.encode(ServerOutgoingMessageType.pong, forKey: .type)
        case .captureResults(let captureResults):
            try container.encode(ServerOutgoingMessageType.captureResults, forKey: .type)
            try captureResults.encode(to: encoder)
        }
    }
}
