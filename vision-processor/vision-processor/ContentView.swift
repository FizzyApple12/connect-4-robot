import SwiftUI

import AVFoundation

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {
    // outside state
    @Binding var pipelineTarget: PipelineTarget
    
    @Binding var serverConnector: ServerConnector
    @Binding var frameGrabber: FrameGrabber
    @Binding var visionPipeline: VisionPipeline
    
    // internal state
    @State private var serverIpSetting: String = "192.168.1.1"
    @FocusState private var serverIpSettingFieldIsFocused: Bool
    @FocusState private var keyboardServerIpSettingFieldIsFocused: Bool
    
    @State private var serverConnectionStateChangedHandlerRemover: () -> Void = {}
    @State private var serverConnectButtonText: String = "connect"
    
    @State private var serverMessageHandlerRemover: () -> Void = {}
    @State private var messageLog: [String] = []
    
    @State private var frameCaptured: Bool = true
    @State private var frameCapturedImage: UIImage? = nil;
    @State private var frameProcessed: Bool = true
    @State private var frameProcessedDebugImage: UIImage? = nil;
    @State private var frameProcessedDebugText: String = ""
    @State private var frameGrabbedHandlerRemover: () -> Void = {}
    
    @State private var pipelineResultsHandlerRemover: () -> Void = {}
    @State private var calibrationResultsHandlerRemover: () -> Void = {}

    func registerOnAppear() {
        serverConnectionStateChangedHandlerRemover = self.serverConnector.registerConnectionStateChangedHandler(setConnectionStateButtonText)
        serverMessageHandlerRemover = self.serverConnector.registerMessageHandler(addMessageToLog)
        
        frameGrabbedHandlerRemover = self.frameGrabber.registerFrameGrabbedHandler(imageCaptured)
        
        pipelineResultsHandlerRemover = self.visionPipeline.registerProcessResultsHandler(imageProcessed)
        calibrationResultsHandlerRemover = self.visionPipeline.registerCalibrationResultsHandler(calibrationProcessed)
    }
    
    func cleanupOnDisappear() {
        serverMessageHandlerRemover()
        serverConnectionStateChangedHandlerRemover()
        
        frameGrabbedHandlerRemover()
        
        pipelineResultsHandlerRemover()
        
        calibrationResultsHandlerRemover()
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
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            TextField("robot server ip", text: $serverIpSetting)
                                .focused($keyboardServerIpSettingFieldIsFocused)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .textFieldStyle(.plain)
                                .keyboardType(.decimalPad)
                                .onChange(of: keyboardServerIpSettingFieldIsFocused, {
                                    serverIpSettingFieldIsFocused = false
                                })
                            Spacer()
                            Button("done") {
                                serverIpSettingFieldIsFocused = false
                                keyboardServerIpSettingFieldIsFocused = false
                                self.endEditing()
                            }
                        }
                    }
                HStack {
                    Button(action: triggerVisionPipelineRun) {
                        Text("trigger")
                    }
                        .buttonStyle(.bordered)
                        .buttonSizing(.flexible)
                    Button(action: triggerVisionPipelineCalibrateFull) {
                        Text("cal full")
                    }
                        .buttonStyle(.bordered)
                        .buttonSizing(.flexible)
                    Button(action: triggerVisionPipelineCalibrateEmpty) {
                        Text("cal empt")
                    }
                        .buttonStyle(.bordered)
                        .buttonSizing(.flexible)
                }
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
                    ScrollView {
                        Text(frameProcessedDebugText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fontDesign(.monospaced)
                            .font(.system(size: 12))
                            .frame(width: 440, alignment: Alignment.topLeading)
                    }
                        .frame(width: 440, height: 200, alignment: Alignment.topLeading)
                    
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
        messageLog.append("manual pipeline run triggered")
        
        pipelineTarget = .normal
        
        frameCaptured = false
        frameProcessed = false
        
        Task {
            await frameGrabber.grab()
        }
    }
    
    func triggerVisionPipelineCalibrateFull() {
        messageLog.append("manual full calibration run triggered")
        
        pipelineTarget = .calibrateFull
        
        frameCaptured = false
        frameProcessed = false
        
        Task {
            await frameGrabber.grab()
        }
    }
    
    func triggerVisionPipelineCalibrateEmpty() {
        messageLog.append("manual empty calibration run triggered")
        
        pipelineTarget = .calibrateEmpty
        
        frameCaptured = false
        frameProcessed = false
        
        Task {
            await frameGrabber.grab()
        }
    }
    
    func imageCaptured(_ image: CGImage) {
        frameCapturedImage = UIImage(cgImage: image)
        frameCaptured = true
    }
    
    func imageProcessed(_ boardState: [[GamePieceType]], _ debugImage: CGImage, _ debugText: String) {
        var finalResults = "[\n"
        
        for row in boardState {
            finalResults += "[ "
            
            for piece in row {
                finalResults += "\"\(piece.rawValue)\", "
            }
            
            finalResults += " ]\n"
        }
        
        finalResults += "\n]";
        
        frameProcessedDebugImage = UIImage(cgImage: debugImage)
        frameProcessedDebugText = debugText + "\n\n" + finalResults
        frameProcessed = true
    }
    
    func calibrationProcessed(_ debugImage: CGImage, _ debugText: String) {
        frameProcessedDebugImage = UIImage(cgImage: debugImage)
        frameProcessedDebugText = debugText
        frameProcessed = true
    }
}

#Preview {
    ContentView(
        pipelineTarget: Binding.constant(PipelineTarget.normal),
        serverConnector: Binding.constant(ServerConnector()),
        frameGrabber: Binding.constant(FrameGrabber()),
        visionPipeline: Binding.constant(VisionPipeline())
    )
}
