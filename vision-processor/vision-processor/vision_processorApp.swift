import SwiftUI

@main
struct vision_processorApp: App {
    @State var serverConnector = ServerConnector()
    
    var body: some Scene {
        WindowGroup {
            ContentView(serverConnector: $serverConnector)
        }
    }
}
