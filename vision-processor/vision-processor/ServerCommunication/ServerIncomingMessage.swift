nonisolated enum ServerIncomingMessageType: String, Codable {
    case ping
    case pong
//    case calibrate
    case capture
}

nonisolated enum ServerIncomingMessage: Codable {
    case ping
    case pong
//    case calibrate
    case capture

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ServerIncomingMessageType.self, forKey: .type)
        
        switch type {
        case .ping:
            self = .ping
        case .pong:
            self = .pong
//        case .calibrate:
//            self = .calibrate
        case .capture:
            self = .capture
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        switch self {
        case .ping:
            try container.encode(ServerIncomingMessageType.ping, forKey: .type)
        case .pong:
            try container.encode(ServerIncomingMessageType.pong, forKey: .type)
//        case .calibrate:
//            try container.encode(ServerIncomingMessageType.calibrate, forKey: .type)
        case .capture:
            try container.encode(ServerIncomingMessageType.capture, forKey: .type)
        }
    }
}
