nonisolated enum ServerIncomingMessageType: String, Codable {
//    case Calibrate
    case Capture
}

nonisolated enum ServerIncomingMessage: Codable {
//    case Calibrate
    case Capture

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ServerIncomingMessageType.self, forKey: .type)
        
        switch type {
//        case .Calibrate:
//            self = .Calibrate
        case .Capture:
            self = .Capture
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        switch self {
//        case .Calibrate:
//            try container.encode(ServerIncomingMessageType.Calibrate, forKey: .type)
        case .Capture:
            try container.encode(ServerIncomingMessageType.Capture, forKey: .type)
        }
    }
}
