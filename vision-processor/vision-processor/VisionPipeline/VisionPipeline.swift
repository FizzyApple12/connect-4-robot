import SwiftUI
import NotificationCenter

import opencv2

let MAX_ALLOWED_ERROR: Double = 50.0

let CIRCLE_FIND_SCALER: Double = 8.0

class VisionPipeline: NSObject {
    private var calibrationResultsNotificationName = NSNotification.Name("VisionProcessor.calibrationResults");
    private var processResultsNotificationName = NSNotification.Name("VisionProcessor.processResults");
    
    private var piecePositions: [[Point2i]] = [];
    
    private var averageRedPieceColour: [Double] = [0, 0, 0, 0]
    private var averageYellowPieceColour: [Double] = [0, 0, 0, 0]

    func initialise() -> Bool {
        
        return true
    }
    
    func process(image: CGImage) {
        Task {
            var debugString = ""
            let initialMat = Mat(cgImage: image)
                
            let debugMat = initialMat
                
            if piecePositions.isEmpty {
                return
            }
            
            var gameboard: [[GamePieceType]] = [];
            
            debugString += "[\n"
                
            for columnIndex in 0...6 {
                var column = [GamePieceType.Blank, GamePieceType.Blank, GamePieceType.Blank, GamePieceType.Blank, GamePieceType.Blank, GamePieceType.Blank]
                
                debugString += "\t[\n"
                
                for rowIndex in 0...5 {
                    let pixelPosition = piecePositions[columnIndex][rowIndex]
                        
                    let colour = initialMat.get(row: pixelPosition.y, col: pixelPosition.x)
                    
                    let redDistance = sqrt(
                        pow(averageRedPieceColour[0] - colour[0], 2)
                        + pow(averageRedPieceColour[1] - colour[1], 2)
                        + pow(averageRedPieceColour[2] - colour[2], 2)
                    )
                    
                    let yellowDistance = sqrt(
                        pow(averageYellowPieceColour[0] - colour[0], 2)
                        + pow(averageYellowPieceColour[1] - colour[1], 2)
                        + pow(averageYellowPieceColour[2] - colour[2], 2)
                    )
                    
                    debugString += "\t\t(\(redDistance), \(yellowDistance)),\n"
                    
                    if redDistance < MAX_ALLOWED_ERROR {
                        column[rowIndex] = GamePieceType.Red
                        
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y), pt2: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y), color: Scalar(0, 255, 0, 255), thickness: 20)
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x, y: pixelPosition.y + 50), color: Scalar(0, 255, 0, 255), thickness: 20)
                    } else if yellowDistance < MAX_ALLOWED_ERROR {
                        column[rowIndex] = GamePieceType.Yellow
                        
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y), pt2: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y), color: Scalar(0, 0, 255, 255), thickness: 20)
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x, y: pixelPosition.y + 50), color: Scalar(0, 0, 255, 255), thickness: 20)
                    } else {
                        column[rowIndex] = GamePieceType.Blank
                        
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y + 50), color: Scalar(255, 0, 0, 255), thickness: 20)
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y + 50), color: Scalar(255, 0, 0, 255), thickness: 20)
                    }
                    
                    Imgproc.putText(img: debugMat, text: "\(columnIndex),\(rowIndex)", org: pixelPosition, fontFace: .FONT_HERSHEY_PLAIN, fontScale: 10, color: Scalar(0, 255, 255, 255), thickness: 20)
                }
                
                debugString += "\n\t],\n"
                
                gameboard.append(column)
            }
            
            debugString += "]\n"
            
            emitProcessResults(gameboard, debugMat.toCGImage(), debugString)
        }
    }
    
    func calibrateFull(image: CGImage) {
        Task {
            var debugString = ""
            let initialMat = Mat(cgImage: image)
            
            let debugMat = initialMat
            
            if piecePositions.isEmpty {
                return
            }
            
            averageRedPieceColour = [0, 0, 0, 0]
            
            var totalRedPieces = 0;
            
            for columnIndex in 0...2 {
                for rowIndex in 0...5 {
                    let pixelPosition = piecePositions[columnIndex][rowIndex]
                    
                    let colour = initialMat.get(row: pixelPosition.y, col: pixelPosition.x)
                    
                    Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y), pt2: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y), color: Scalar(0, 255, 0, 255), thickness: 20)
                    Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x, y: pixelPosition.y + 50), color: Scalar(0, 255, 0, 255), thickness: 20)
                    
                    averageRedPieceColour[0] += colour[0]
                    averageRedPieceColour[1] += colour[1]
                    averageRedPieceColour[2] += colour[2]
                    averageRedPieceColour[3] += colour[3]
                    
                    totalRedPieces += 1
                }
            }
            
            averageRedPieceColour[0] = averageRedPieceColour[0] / Double(totalRedPieces)
            averageRedPieceColour[1] = averageRedPieceColour[1] / Double(totalRedPieces)
            averageRedPieceColour[2] = averageRedPieceColour[2] / Double(totalRedPieces)
            averageRedPieceColour[3] = averageRedPieceColour[3] / Double(totalRedPieces)
            
            debugString += "average red piece colour: \(averageRedPieceColour)\n\n"

            averageYellowPieceColour = [0, 0, 0, 0]
            
            var totalYellowPieces = 0;
            
            for columnIndex in 4...6 {
                for rowIndex in 0...5 {
                    let pixelPosition = piecePositions[columnIndex][rowIndex]
                    
                    let colour = initialMat.get(row: pixelPosition.y, col: pixelPosition.x)
                    
                    Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y), pt2: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y), color: Scalar(0, 0, 255, 255), thickness: 20)
                    Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x, y: pixelPosition.y + 50), color: Scalar(0, 0, 255, 255), thickness: 20)
                    
                    averageYellowPieceColour[0] += colour[0]
                    averageYellowPieceColour[1] += colour[1]
                    averageYellowPieceColour[2] += colour[2]
                    averageYellowPieceColour[3] += colour[3]
                    
                    totalYellowPieces += 1
                }
            }
            
            averageYellowPieceColour[0] = averageYellowPieceColour[0] / Double(totalYellowPieces)
            averageYellowPieceColour[1] = averageYellowPieceColour[1] / Double(totalYellowPieces)
            averageYellowPieceColour[2] = averageYellowPieceColour[2] / Double(totalYellowPieces)
            averageYellowPieceColour[3] = averageYellowPieceColour[3] / Double(totalYellowPieces)
            
            debugString += "average yellow piece colour: \(averageYellowPieceColour)\n\n"
            
            emitCalibrationResults(debugMat.toCGImage(), debugString)
        }
    }
    
    func calibrateEmpty(image: CGImage) {
        Task {
            var debugString = ""
            let initialMat = Mat(cgImage: image)
            
            let smallerMat = Mat(cgImage: image)
                
            let grayScaleMat = Mat()
            let grayScaleMat2 = Mat()
                
            let debugMat = initialMat
                
            Imgproc.resize(src: initialMat, dst: smallerMat, dsize: Size2i(width: initialMat.width() / Int32(CIRCLE_FIND_SCALER), height: initialMat.height() / Int32(CIRCLE_FIND_SCALER)))
                
            Imgproc.cvtColor(src: smallerMat, dst: grayScaleMat, code: .COLOR_BGR2GRAY)
            Core.bitwise_not(src: grayScaleMat, dst: grayScaleMat2)
                
            let centersMat = Mat()
                
            let gridFound = Calib3d.findCirclesGrid(image: grayScaleMat2, patternSize: Size2i(width: 7, height: 6), centers: centersMat)
            
            debugString += "found grid: \(gridFound)\n\n"
                
            piecePositions = []
            
            if gridFound && centersMat.rows() >= 41 {
                for columnIndex in 0...6 {
                    var columnPositions = [ Point2i(), Point2i(), Point2i(), Point2i(), Point2i(), Point2i() ]
                    
                    for rowIndex in 0...5 {
                        let circleIndex = Int32(rowIndex * 7 + columnIndex)
                        
                        let circlePosition = centersMat.get(row: circleIndex, col: 0)
                        
                        let pixelPosition = Point2i(x: Int32(circlePosition[0] * CIRCLE_FIND_SCALER), y: Int32(circlePosition[1] * CIRCLE_FIND_SCALER))
                        
                        columnPositions[5 - rowIndex] = pixelPosition
                        
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x - 50, y: pixelPosition.y), pt2: Point2i(x: pixelPosition.x + 50, y: pixelPosition.y), color: Scalar(0, 255, 0, 255), thickness: 20)
                        Imgproc.line(img: debugMat, pt1: Point2i(x: pixelPosition.x, y: pixelPosition.y - 50), pt2: Point2i(x: pixelPosition.x, y: pixelPosition.y + 50), color: Scalar(0, 255, 0, 255), thickness: 20)
                        
                        Imgproc.putText(img: debugMat, text: "\(circleIndex)", org: pixelPosition, fontFace: .FONT_HERSHEY_PLAIN, fontScale: 10, color: Scalar(0, 255, 255, 255), thickness: 20)
                    }
                    
                    piecePositions.append(columnPositions)
                }
            }
            
            debugString += "position map: \(piecePositions)"
            
            emitCalibrationResults(debugMat.toCGImage(), debugString)
        }
    }
    
    func registerProcessResultsHandler(_ handler: @escaping ([[GamePieceType]], CGImage, String) -> Void) -> () -> Void {
        let observer = NotificationCenter.default.addObserver(forName: processResultsNotificationName, object: nil, queue: nil) { eventObject in
            let arguments = eventObject.object as! ([[GamePieceType]], CGImage, String)
            
            handler(arguments.0, arguments.1, arguments.2)
        }
        
        return { NotificationCenter.default.removeObserver(observer) }
        
    }
    private func emitProcessResults(_ boardState: [[GamePieceType]], _ debugImage: CGImage, _ debugText: String) {
        NotificationCenter.default.post(name: processResultsNotificationName, object: (boardState, debugImage, debugText))
    }
    
    func registerCalibrationResultsHandler(_ handler: @escaping (CGImage, String) -> Void) -> () -> Void {
        let observer = NotificationCenter.default.addObserver(forName: calibrationResultsNotificationName, object: nil, queue: nil) { eventObject in
            let arguments = eventObject.object as! (CGImage, String)
            
            handler(arguments.0, arguments.1)
        }
        
        return { NotificationCenter.default.removeObserver(observer) }
        
    }
    private func emitCalibrationResults(_ debugImage: CGImage, _ debugText: String) {
        NotificationCenter.default.post(name: calibrationResultsNotificationName, object: (debugImage, debugText))
    }
}
