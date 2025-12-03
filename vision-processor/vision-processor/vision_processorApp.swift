import SwiftUI

@main
struct vision_processorApp: App {
    @State var serverConnector = ServerConnector()
    @State var frameGrabber = FrameGrabber()
    
    func registerOnAppear() {
        Task {
            await frameGrabber.initialise()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(serverConnector: $serverConnector, frameGrabber: $frameGrabber)
                .onAppear(perform: registerOnAppear)
        }
    }
}
