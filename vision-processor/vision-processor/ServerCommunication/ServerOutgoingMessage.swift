nonisolated enum GamePieceType: String, Codable {
    case Red
    case Yellow
    case Blank
}

//nonisolated enum ServerOutgoingMessageType: String, Codable {
//    case CaptureResults
//}

struct CaptureResultsType: Codable {
    let state: [[GamePieceType]]
}

struct ServerOutgoingMessage: Codable {
    var CaptureResults: CaptureResultsType?
//    case CaptureResults(CaptureResultsType)
//    
//    struct CaptureResultsType: Codable {
//        let state: [[GamePieceType]]
//    }
//
//    private enum CodingKeys: String, CodingKey {
//        case CaptureResults
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let type = try container.decode(ServerOutgoingMessageType.self, forKey: .CaptureResults)
//        
//        switch type {
//        case .CaptureResults:
//            self = .CaptureResults(try CaptureResultsType(from: decoder))
//        }
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//            
//        switch self {
//        case .CaptureResults(let captureResults):
//            try container.encode(ServerOutgoingMessageType.CaptureResults, forKey: .type)
//            try captureResults.encode(to: encoder)
//        }
//    }
}
