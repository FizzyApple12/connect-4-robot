import SwiftUI

import AVFoundation

struct ContentView: View {
    // outside state
    @Binding var serverConnector: ServerConnector
    @Binding var frameGrabber: FrameGrabber
    
    // internal state
    @State private var serverIpSetting: String = ""
    @FocusState private var serverIpSettingFieldIsFocused: Bool
    
    @State private var serverConnectionStateChangedHandlerRemover: () -> Void = {}
    @State private var serverConnectButtonText: String = "connect"
    
    @State private var serverMessageHandlerRemover: () -> Void = {}
    @State private var messageLog: [String] = []
    
    @State private var frameCaptured: Bool = false
    @State private var frameCapturedImage: UIImage? = nil;
    @State private var frameProcessed: Bool = false
    @State private var frameProcessedDebugImage: UIImage? = nil;
    @State private var frameProcessedDebugText: String = ""
    @State private var frameGrabbedHandlerRemover: () -> Void = {}

    func registerOnAppear() {
        serverConnectionStateChangedHandlerRemover = self.serverConnector.registerConnectionStateChangedHandler(setConnectionStateButtonText)
        serverMessageHandlerRemover = self.serverConnector.registerMessageHandler(addMessageToLog)
        
        frameGrabbedHandlerRemover = self.frameGrabber.registerFrameGrabbedHandler(imageCaptured)
    }
    
    func cleanupOnDisappear() {
        serverMessageHandlerRemover()
        serverConnectionStateChangedHandlerRemover()
        
        frameGrabbedHandlerRemover()
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    TextField(
                        "robot server ip",
                        text: $serverIpSetting
                    )
                        .focused($serverIpSettingFieldIsFocused)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    Spacer()
                    Button(action: triggerConnectOrDisconnect) {
                        Text(serverConnectButtonText)
                    }
                        .buttonStyle(.bordered)
                        .buttonSizing(.flexible)
                }
                Button(action: triggerVisionPipelineRun) {
                    Text("manually trigger vision pipeline")
                }
                    .buttonStyle(.bordered)
                    .buttonSizing(.flexible)
            }
            
            Spacer()
            
            HStack {
                VStack {
                    Text("raw camera")
                    
                    ZStack {
                        if let frameCapturedImage = frameCapturedImage {
                            Image(uiImage: frameCapturedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Rectangle())
                                .frame(width: 220, height: 220)
                        }
                        
                        if (!frameCaptured) {
                            Rectangle()
                                .fill(.black)
                                .opacity(0.80)
                                .ignoresSafeArea()
                            
                            VStack {
                                ProgressView()
                                Text("Capturing...")
                            }
                        }
                    }
                        .frame(width: 220, height: 220)
                }
                VStack {
                    Text("processed camera")
                    
                    ZStack {
                        if let frameProcessedDebugImage = frameProcessedDebugImage {
                            Image(uiImage: frameProcessedDebugImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Rectangle())
                                .frame(width: 220, height: 220)
                        }
                            
                        if (!frameProcessed) {
                            Rectangle()
                                .fill(.black)
                                .opacity(0.80)
                                .ignoresSafeArea()
                        
                            VStack {
                                ProgressView()
                                Text("Processing...")
                            }
                        }
                    }
                        .frame(width: 220, height: 220)
                }
            }
            
            Spacer()
            
            VStack {
                Text("vision pipeline results")
                ZStack {
                    Text(frameProcessedDebugText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(width: 440, height: 200, alignment: Alignment.topLeading)
                        .fontDesign(.monospaced)
                        .font(.system(size: 12))
                    
                    if (!frameProcessed) {
                        Rectangle()
                            .fill(.black)
                            .opacity(0.80)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                            Text("Waiting for process results...")
                        }
                    }
                }
                    .frame(height: 200)
            }
            
            Spacer()
            
            VStack {
                HStack {
                    Text("command feed")
                    
                    Button(action: clearLog) {
                        Text("clear")
                    }
                        .buttonStyle(.bordered)
                        .buttonSizing(.flexible)
                }
                ScrollView {
                    LazyVStack {
                        ForEach(Array($messageLog.enumerated()), id: \.0) { index, message in
                            Text(message.wrappedValue)
                                .frame(width: 440, alignment: Alignment.topLeading)
                                .fontDesign(.monospaced)
                                .font(.system(size: 12))
                        }
                    }
                }
                    .frame(width: 440, height: 200, alignment: Alignment.topLeading)
            }
        }
            .onAppear(perform: registerOnAppear)
            .onDisappear(perform: cleanupOnDisappear)
    }
    
    
    func setConnectionStateButtonText(_ connectionState: ServerConnectionState) {
        switch connectionState {
        case .disconnected:
            serverConnectButtonText = "connect"
        case let .connecting(ip, _):
            serverConnectButtonText = "abort " + ip
        case let .connected(ip, _):
            serverConnectButtonText = "disconnect " + ip
        }
    }
    
    func addMessageToLog(_ message: ServerIncomingMessage) {
        do {
            let messageEncoder = JSONEncoder()
            if let messageJSON: String = String(data: try messageEncoder.encode(message), encoding: String.Encoding.utf8) {
                messageLog.append(messageJSON)
            }
        } catch {
            print("Error printing message: \(error)")
        }
    }
    
    func clearLog() {
        messageLog = []
    }
    
    func triggerConnectOrDisconnect() {
        switch serverConnector.connectionState {
        case .disconnected:
            serverConnector.connect(ip: serverIpSetting)
        case .connecting(_, _), .connected(_, _):
            serverConnector.disconnect()
        }
    }
    
    func triggerVisionPipelineRun() {
        messageLog.append("manual capture triggered")
        frameCaptured = false
        frameProcessed = false
        frameGrabber.grab()
    }
    
    func imageCaptured(_ image: CGImage) {
        frameCapturedImage = UIImage(cgImage: image)
        frameCaptured = true
        
        imageProcessed(image, "test")
    }
    
    func imageProcessed(_ debugImage: CGImage, _ debugText: String) {
        frameProcessedDebugImage = UIImage(cgImage: debugImage)
        frameProcessedDebugText = debugText
        frameProcessed = true
    }
}

#Preview {
    ContentView(serverConnector: Binding.constant(ServerConnector()), frameGrabber: Binding.constant(FrameGrabber()))
}
