import SwiftUI

public enum PipelineTarget {
    case normal
    case calibrateFull
    case calibrateEmpty
}

@main
struct vision_processorApp: App {
    @State var pipelineTarget = PipelineTarget.normal
    
    @State var serverConnector = ServerConnector()
    @State var frameGrabber = FrameGrabber()
    @State var visionPipeline = VisionPipeline()
    
    @State private var serverMessageHandlerRemover: () -> Void = {}
    @State private var frameGrabbedHandlerRemover: () -> Void = {}
    @State private var pipelineResultsHandlerRemover: () -> Void = {}
    
    func registerOnAppear() {
        serverMessageHandlerRemover = serverConnector.registerMessageHandler(onServerMessage)
        frameGrabbedHandlerRemover = frameGrabber.registerFrameGrabbedHandler(onFrameGrabbed)
        pipelineResultsHandlerRemover = visionPipeline.registerProcessResultsHandler(onPipelineResults)
        
        Task {
            let _ = await frameGrabber.initialise()
            let _ = visionPipeline.initialise()
        }
    }
    
    func cleanupOnDisappear() {
        serverMessageHandlerRemover()
        
        frameGrabbedHandlerRemover()
        
        pipelineResultsHandlerRemover()
        
        frameGrabber.destroy()
    }
    
    func onServerMessage(_ incomingMessage: ServerIncomingMessage) {
        if incomingMessage == ServerIncomingMessage.Capture {
            pipelineTarget = .normal
            
            Task {
                await frameGrabber.grab()
            }
        }
    }
    
    func onFrameGrabbed(_ frame: CGImage) {
        if pipelineTarget == .normal {
            visionPipeline.process(image: frame)
        } else if pipelineTarget == .calibrateFull {
            visionPipeline.calibrateFull(image: frame)
        } else if pipelineTarget == .calibrateEmpty {
            visionPipeline.calibrateEmpty(image: frame)
        }
    }
    
    func onPipelineResults(_ boardState: [[GamePieceType]], _ debugFrame: CGImage, _ debugText: String) {
        serverConnector.sendMessage(ServerOutgoingMessage.init(CaptureResults: CaptureResultsType(state: boardState)))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                pipelineTarget: $pipelineTarget,
                serverConnector: $serverConnector,
                frameGrabber: $frameGrabber,
                visionPipeline: $visionPipeline
            )
                .onAppear(perform: registerOnAppear)
                .onDisappear(perform: cleanupOnDisappear)
        }
    }
}
