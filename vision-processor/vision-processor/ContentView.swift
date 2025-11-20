import SwiftUI

import AVFoundation

struct ContentView: View {
    // outside state
    @Binding var serverConnector: ServerConnector
    
    // internal state
    @State private var serverIpSetting: String = ""
    @FocusState private var serverIpSettingFieldIsFocused: Bool
    
    @State private var serverConnectionStateChangedHandlerRemover: () -> Void = {}
    @State private var serverConnectButtonText: String = "connect"
    
    @State private var serverMessageHandlerRemover: () -> Void = {}
    @State private var messageLog: [String] = []
    
    // testing
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let testOutput = CameraCaptureOutput()
    
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            // Determine whether a person previously authorized camera access.
            var isAuthorized = status == .authorized
            // If the system hasn't determined their authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }

    func registerOnAppear() {
        serverConnectionStateChangedHandlerRemover = self.serverConnector.registerConnectionStateChangedHandler(setConnectionStateButtonText)
        serverMessageHandlerRemover = self.serverConnector.registerMessageHandler(addMessageToLog)
        
        Task {
            captureSession.startRunning()
            
            captureSession.beginConfiguration()
            
            if !isAuthorized { return }
            
            let videoDevice = AVCaptureDevice.default(for: .video)
            guard
                let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
                captureSession.canAddInput(videoDeviceInput)
            else { return }
            
            captureSession.addInput(videoDeviceInput)
            
            guard captureSession.canAddOutput(photoOutput) else { return }
            captureSession.sessionPreset = .photo
            captureSession.addOutput(photoOutput)
            captureSession.commitConfiguration()
        }
    }
    
    func cleanupOnDisappear() {
        serverMessageHandlerRemover()
        serverConnectionStateChangedHandlerRemover()
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
                        Image(.testImages)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Rectangle())
                            .frame(width: 220, height: 220)
                        
                        Rectangle()
                            .fill(.black)
                            .opacity(0.80)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                            Text("Capturing...")
                        }
                            .colorInvert()
                    }
                        .frame(width: 220, height: 220)
                }
                VStack {
                    Text("processed camera")
                    
                    ZStack {
                        Image(.testImages)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Rectangle())
                            .frame(width: 220, height: 220)
                        
                        Rectangle()
                            .fill(.black)
                            .opacity(0.80)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                            Text("Processing...")
                        }
                            .colorInvert()
                    }
                        .frame(width: 220, height: 220)
                }
            }
            
            Spacer()
            
            VStack {
                Text("vision pipeline results")
                ZStack {
                    Text("vision pipeline results\nvision pipeline results\nvision pipeline results\nvision pipeline results\nvision pipeline results\nvision pipeline results\nvision pipeline results\nvision pipeline results\nvision pipeline results\n")
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(width: 440, height: 200, alignment: Alignment.topLeading)
                        .fontDesign(.monospaced)
                        .font(.system(size: 12))
                    
                    Rectangle()
                        .fill(.black)
                        .opacity(0.80)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                        Text("Waiting for process results...")
                    }
                        .colorInvert()
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
        photoOutput.capturePhoto(with: AVCapturePhotoSettings.init(), delegate: testOutput)
    }
}

#Preview {
    ContentView(serverConnector: Binding.constant(ServerConnector()))
}
