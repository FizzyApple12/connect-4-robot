import NotificationCenter;
import Foundation;
import NWWebSocket;
import Network;

//enum ServerConnectionState {
//    case disconnected
//    case connecting(ip: String, websocketConnection: URLSessionWebSocketTask)
//    case connected(ip: String, websocketConnection: URLSessionWebSocketTask)
//}

enum ServerConnectionState {
    case disconnected
    case connecting(ip: String, websocketConnection: NWWebSocket)
    case connected(ip: String, websocketConnection: NWWebSocket)
}

// , URLSessionWebSocketDelegate
class ServerConnector: NSObject, WebSocketConnectionDelegate {
    var connectionState: ServerConnectionState {
        get {
            internalConnectionState
        }
    }
    
    private var connectionStateChangedNotificationName = NSNotification.Name("ServerConnector.connectionStateChanged");
    private var messageNotificationName = NSNotification.Name("ServerConnector.message");
    
    private var internalConnectionState: ServerConnectionState = ServerConnectionState.disconnected
    
    func connect(ip: String) {
        disconnect()
        
        let urlString = "ws://\(ip):4226/board_reader"
        
        print("url: \(urlString)")
        
        if let url = URL(string: urlString) {
//            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            
//            let webSocket = session.webSocketTask(with: url)
            let socket = NWWebSocket(url: url)
            socket.delegate = self
            
            internalConnectionState = ServerConnectionState.connecting(ip: ip, websocketConnection: socket)
            
            emitConnectionStateChangedNotification()
            
            socket.connect()
            
//            webSocket.resume()
            
//            receiveMessage()
        }
    }
    
    func disconnect() {
        switch internalConnectionState {
        case let .connecting(_, websocketConnection):
//            websocketConnection.cancel()
            websocketConnection.disconnect()
            
            internalConnectionState = ServerConnectionState.disconnected
            
            emitConnectionStateChangedNotification()
            break;
            
        case let .connected(_, websocketConnection):
            websocketConnection.disconnect()
//            websocketConnection.cancel(with: .goingAway, reason: nil)
            
            internalConnectionState = ServerConnectionState.disconnected
            
            emitConnectionStateChangedNotification()
            break;
        default:
            internalConnectionState = ServerConnectionState.disconnected
            
            emitConnectionStateChangedNotification()
            break;
        }
    }
    
    func registerConnectionStateChangedHandler(_ handler: @escaping (ServerConnectionState) -> Void) -> () -> Void {
        let observer = NotificationCenter.default.addObserver(forName: connectionStateChangedNotificationName, object: nil, queue: nil) { _ in
            handler(self.connectionState)
        }
        
        return { NotificationCenter.default.removeObserver(observer) }
    }
    private func emitConnectionStateChangedNotification() {
        NotificationCenter.default.post(name: connectionStateChangedNotificationName, object: nil)
    }
    
    func registerMessageHandler(_ handler: @escaping (ServerIncomingMessage) -> Void) -> () -> Void {
        let observer = NotificationCenter.default.addObserver(forName: messageNotificationName, object: nil, queue: nil) { eventObject in
            handler(eventObject.object as! ServerIncomingMessage)
        }
        
        return { NotificationCenter.default.removeObserver(observer) }
        
    }
    private func emitMessageNotification(_ message: ServerIncomingMessage) {
        NotificationCenter.default.post(name: messageNotificationName, object: message)
    }
    
//    func receiveMessage() {
//        switch internalConnectionState {
//        case let .connecting(_, websocketConnection),
//            let .connected(_, websocketConnection):
//            websocketConnection.receive(completionHandler: { [weak self] result in
//                do {
//                    let messageDecoder = JSONDecoder()
//                
//                    switch result {
//                    case let .failure(error):
//                        print(error.localizedDescription)
//                    case let .success(message):
//                        switch message {
//                        case let .string(messageString):
//                            let decodedMessage = try messageDecoder.decode(ServerIncomingMessage.self, from: Data(messageString.utf8))
//                            self?.emitMessageNotification(decodedMessage)
//                        case let .data(data):
//                            let decodedMessage = try messageDecoder.decode(ServerIncomingMessage.self, from: data)
//                            self?.emitMessageNotification(decodedMessage)
//                        default:
//                            print("Unknown type received from WebSocket")
//                        }
//                    }
//                } catch {
//                    print("Error during JSON serialize: \(error)")
//                }
//                self?.receiveMessage()
//            })
//        default:
//            print("Cannot receive message unless we are connected")
//        }
//    }
    
    func sendMessage(_ message: ServerOutgoingMessage) {
        do {
            let messageEncoder = JSONEncoder()
            if let messageJSON: String = String(data: try messageEncoder.encode(message), encoding: String.Encoding.utf8) {
                switch internalConnectionState {
                case let .connecting(_, websocketConnection),
                    let .connected(_, websocketConnection):
//                    websocketConnection.send(URLSessionWebSocketTask.Message.string(messageJSON)) { error in
//                        if let error = error {
//                            print("Send failed with Error \(error.localizedDescription)")
//                        } else {
//                            // no-op
//                        }
//                    }
                    websocketConnection.send(string: messageJSON)
                default:
                    print("Cannot send message unless we are connected")
                }
            }
        } catch {
            print("Error during JSON serialize: \(error)")
        }
    }
    
//    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
//        switch internalConnectionState {
//        case let .connecting(ip, websocketConnection),
//            let .connected(ip, websocketConnection):
//            internalConnectionState = ServerConnectionState.connected(ip: ip, websocketConnection: websocketConnection)
//            
//            emitConnectionStateChangedNotification()
//        default:
//            print("Unexpected internal connection state: \(internalConnectionState)")
//        }
//    }
//
//    
//    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
//        internalConnectionState = ServerConnectionState.disconnected
//        
//        emitConnectionStateChangedNotification()
//    }
    func webSocketDidConnect(connection: WebSocketConnection) {
        switch internalConnectionState {
        case let .connecting(ip, websocketConnection):
            internalConnectionState = ServerConnectionState.connected(ip: ip, websocketConnection: websocketConnection)
            
            emitConnectionStateChangedNotification()
            
            break;
            
        case let .connected(ip, websocketConnection):
            internalConnectionState = ServerConnectionState.connected(ip: ip, websocketConnection: websocketConnection)
            
            emitConnectionStateChangedNotification()
            
            break;
        default:
            self.disconnect()
            break;
        }
    }

    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        self.disconnect()
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        if !isViable {
            self.disconnect()
        }
    }

    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {}

    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        self.disconnect()
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {}

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        do {
            let messageDecoder = JSONDecoder()
        
            let decodedMessage = try messageDecoder.decode(ServerIncomingMessage.self, from: Data(string.utf8))
            self.emitMessageNotification(decodedMessage)
        } catch {
            print("Error during JSON deserialize: \(error)")
        }
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        do {
            let messageDecoder = JSONDecoder()
        
            let decodedMessage = try messageDecoder.decode(ServerIncomingMessage.self, from: data)
            self.emitMessageNotification(decodedMessage)
        } catch {
            print("Error during JSON deserialize: \(error)")
        }
    }
}
