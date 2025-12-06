import NotificationCenter;
import Foundation;
import Starscream
import Network;

//enum ServerConnectionState {
//    case disconnected
//    case connecting(ip: String, websocketConnection: URLSessionWebSocketTask)
//    case connected(ip: String, websocketConnection: URLSessionWebSocketTask)
//}

enum ServerConnectionState {
    case disconnected
    case connecting(ip: String, websocketConnection: Starscream.WebSocket)
    case connected(ip: String, websocketConnection: Starscream.WebSocket)
}

// , URLSessionWebSocketDelegate
class ServerConnector: NSObject, WebSocketDelegate {
    var connectionState: ServerConnectionState {
        get {
            internalConnectionState
        }
    }
    
    private var connectionStateChangedNotificationName = NSNotification.Name("ServerConnector.connectionStateChanged");
    private var messageNotificationName = NSNotification.Name("ServerConnector.message");
    
    private var internalConnectionState: ServerConnectionState = ServerConnectionState.disconnected
    private var lastValidUrl: URL?
    
    func connect(ip: String) {
        disconnect()
        
        let urlString = "ws://\(ip):4226/board_reader"
        print("url: \(urlString)")
        
        if let url = URL(string: urlString) {
            lastValidUrl = url
//            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            
//            let webSocket = session.webSocketTask(with: url)
            var req = URLRequest(url: url)
            req.timeoutInterval = 5.0
            let socket = WebSocket(request: req, certPinner: FoundationSecurity(allowSelfSigned: true))
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
    
    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
        case .connected(let dictionary):
            switch internalConnectionState {
            case let .connecting(ip, websocketConnection):
                fallthrough
            case let .connected(ip, websocketConnection):
                internalConnectionState = ServerConnectionState.connected(ip: ip, websocketConnection: websocketConnection)
                
                emitConnectionStateChangedNotification()
                
                break;
            default:
                self.disconnect()
                break;
            }
        case .disconnected(let string, let uInt16):
            self.disconnect()
        case .text(let string):
            print("message: \(string)")
            handleRecvMsg(Data(string.utf8))
        case .binary(let data):
            print("message: \(data)")
            handleRecvMsg(data)
        case .pong(let data):
            break
        case .ping(let data):
            client.write(pong: data ?? Data())
        case .error(let error):
            self.disconnect()
        case .viabilityChanged(let bool):
            if !bool {
                self.disconnect()
            }
        case .reconnectSuggested(let bool):
            if bool, let lastValidUrl {
                self.connect(ip: lastValidUrl.absoluteString)
            }
        case .cancelled:
            self.disconnect()
        case .peerClosed:
            self.disconnect()
        }
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
                    
                    print("send: \(messageJSON)")
                    
                    websocketConnection.write(string: messageJSON)
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
    
    private func handleRecvMsg(_ msg: Data) {
//        do {
//            let decodedMessage = try JSONDecoder().decode(ServerIncomingMessage.self, from: msg)
//        } catch {
//            print("Error during JSON deserialize: \(error)")
//        }
        if msg == Data("\"Capture\"".utf8) {
            self.emitMessageNotification(ServerIncomingMessage.Capture)
        } else {
            print("Error during JSON deserialize: what")
        }
    }
}
