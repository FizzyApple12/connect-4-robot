import AVFoundation
import SwiftUI

class CameraCaptureOutput: NSObject, AVCapturePhotoCaptureDelegate {

//    let cameraOutput = AVCapturePhotoOutput()
//
//    func capturePhoto() {
//        let settings = AVCapturePhotoSettings()
//        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
//                            kCVPixelBufferWidthKey as String: 160,
//                            kCVPixelBufferHeightKey as String: 160]
//        settings.previewPhotoFormat = previewFormat
//        self.cameraOutput.capturePhoto(with: settings, delegate: self)
//
//    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }

        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print("image: \(UIImage(data: dataImage)?.size)") // Your Image
        }
    }
}
