import AVFoundation
import SwiftUI
import NotificationCenter

class FrameGrabber: NSObject, AVCapturePhotoCaptureDelegate {
    let latestFrame: CGImage? = nil
    
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    private var frameGrabbedNotificationName = NSNotification.Name("FrameGrabber.frameGrabbed");
    
    func initialise() async -> Bool {
//        captureSession.beginConfiguration()
//        
//        let status = AVCaptureDevice.authorizationStatus(for: .video)
//        
//        var isAuthorized = status == .authorized
//        
//        if status == .notDetermined {
//            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
//        }
//        
//        if !isAuthorized { return false; }
//        
//        let videoDevice = AVCaptureDevice.default(for: .video)
//        guard
//            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
//            captureSession.canAddInput(videoDeviceInput)
//        else { return false }
//        
//        captureSession.addInput(videoDeviceInput)
//    
//        guard captureSession.canAddOutput(photoOutput) else { return false }
//        captureSession.sessionPreset = .photo
//        captureSession.addOutput(photoOutput)
//        captureSession.commitConfiguration()
//        
//        captureSession.startRunning()
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        var isAuthorized = status == .authorized
        
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        if !isAuthorized { return false; }
        
        captureSession.beginConfiguration()
        
        let captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.filter { $0.position == .back }.first
        
        guard
            let captureDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            return false
        }
        
        captureSession.sessionPreset = .photo
        
        guard captureSession.canAddInput(deviceInput) else {
            return false
        }
        guard captureSession.canAddOutput(photoOutput) else {
            return false
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(photoOutput)
        
        photoOutput.maxPhotoDimensions = deviceInput.device.activeFormat.supportedMaxPhotoDimensions.last!

        photoOutput.maxPhotoQualityPrioritization = .quality
        photoOutput.isConstantColorEnabled = true
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
        
        return true
    }
    
    func grab() {
        let settings = AVCapturePhotoSettings()
//        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
//                            kCVPixelBufferWidthKey as String: 1024,
//                            kCVPixelBufferHeightKey as String: 1024]
//        settings.previewPhotoFormat = previewFormat
//        settings.format =
        settings.flashMode = .on
        settings.isConstantColorEnabled = true
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        print("frame grabbed")
        
        if let error = error {
            print(error.localizedDescription)
            
            return;
        }
        
        if let sampleBuffer = photoSampleBuffer {
            
            print("photo buffer present")
            
            if let imageBuffer = sampleBuffer.dataBuffer {
                
//                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                
                print("image buffer found")
                
//                let context = CIContext(options: nil)
                
//                if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
////                    return cgImage
//                }
            }
        }
    }
    
//    func CVImageBufferToCGImage(_ imageBuffer: CVPixelBuffer) -> CGImage? {
//        var cgImage: CGImage?
//        
//        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//        
//        CVPixelBufferLockBaseAddress(imageBuffer, [])
//        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
//        
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//    }
    
    func registerFrameGrabbedHandler(_ handler: @escaping (CGImage) -> Void) -> () -> Void {
        let observer = NotificationCenter.default.addObserver(forName: frameGrabbedNotificationName, object: nil, queue: nil) { eventObject in
            handler(eventObject.object as! CGImage)
        }
        
        return { NotificationCenter.default.removeObserver(observer) }
        
    }
    private func emitFrameGrabbed(_ message: CGImage) {
        NotificationCenter.default.post(name: frameGrabbedNotificationName, object: message)
    }
}
