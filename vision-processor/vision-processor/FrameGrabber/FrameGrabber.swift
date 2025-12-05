import AVFoundation
import SwiftUI
import NotificationCenter

class FrameGrabber: NSObject, AVCapturePhotoCaptureDelegate {
    private let captureSession = AVCaptureSession()
    
    private var captureDevice: AVCaptureDevice? = nil
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private var frameGrabbedNotificationName = NSNotification.Name("FrameGrabber.frameGrabbed");
    
    func initialise() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        var isAuthorized = status == .authorized
        
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        if !isAuthorized { return false; }
        
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = .photo
        
        captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.filter { $0.position == .back }.first
        
        guard
            let captureDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            return false
        }
        
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
//        photoOutput.isConstantColorEnabled = true
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
        
        try! captureDevice.lockForConfiguration()
        
        await captureDevice.setWhiteBalanceModeLocked(with: AVCaptureDevice.WhiteBalanceGains(redGain: 1.0, greenGain: 1.0, blueGain: 1.0))
        
        captureDevice.unlockForConfiguration()
        
        return true
    }
    
    func destroy() {
    }
    
    func grab() async {
        let settings = AVCapturePhotoSettings()
//        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
//                            kCVPixelBufferWidthKey as String: 1024,
//                            kCVPixelBufferHeightKey as String: 1024]
//        settings.previewPhotoFormat = previewFormat
//        settings.format =
        settings.flashMode = .on
//        settings.isConstantColorEnabled = true
//        settings.isConstantColorFallbackPhotoDeliveryEnabled = false
        settings.photoQualityPrioritization = .quality
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        
//        guard
//            let captureDevice = captureDevice
//        else {
//            return
//        }
        
//        await captureDevice.setExposureModeCustom(duration: captureDevice.activeFormat.minExposureDuration, iso: 100)
//        await captureDevice.setExposureTargetBias(captureDevice.minExposureTargetBias)
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            
            return;
        }
        
        if let finalPhoto = photoToUIImage(photo: photo), let photoCGImage = finalPhoto.cgImage {
//            print("photo buffer present: \(finalPhoto.size)")
            emitFrameGrabbed(photoCGImage)
        }
    }
    
    private func photoToUIImage(photo: AVCapturePhoto!) -> UIImage! {
        let imageData = photo?.fileDataRepresentation()
        return imageData.flatMap { UIImage(data: $0) }
    }
    
    func registerFrameGrabbedHandler(_ handler: @escaping (CGImage) -> Void) -> () -> Void {
        let observer = NotificationCenter.default.addObserver(forName: frameGrabbedNotificationName, object: nil, queue: nil) { eventObject in
            handler(eventObject.object as! CGImage)
        }
        
        return { NotificationCenter.default.removeObserver(observer) }
        
    }
    private func emitFrameGrabbed(_ frame: CGImage) {
        NotificationCenter.default.post(name: frameGrabbedNotificationName, object: frame)
    }
}
