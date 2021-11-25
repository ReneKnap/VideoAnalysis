//
//  ViewController.swift
//  VideoAnalysis
//
//  Created by Creatcher on 18.11.21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var cameraSession: AVCaptureSession!
    var captureInput: AVCaptureInput!
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var stillImageOutput: AVCapturePhotoOutput!
    
    var stillImage: UIImage!
    var sepiaToneButton: UIButton!
    var eyeDetectionButton: UIButton!
    
    var edgesButton: UIButton!
    var filteredImage: UIImageView!
    var previewImage: UIImageView!
    
    let context = CIContext()
    var filter = CIFilter()
    
    var filterSepiaState = false
    var filterEdgeState = false
    var eyeDetectionState = false
    var imageAspectRatio = CGFloat(1)
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUIElements()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageAspectRatio = (previewImage.frame.size.height / previewImage.frame.size.width)
        loadCamera()
    }
    
    func loadUIElements() {
        view.backgroundColor = UIColor.black
        sepiaToneButton = UIButton()

        sepiaToneButton = UIButton(type: .system)
        sepiaToneButton.translatesAutoresizingMaskIntoConstraints = false
        sepiaToneButton.setTitle("SepiaTone", for: .normal)
        sepiaToneButton.addTarget(self, action: #selector(changeFilterToSepiaTone), for: .touchUpInside)
        sepiaToneButton.backgroundColor = UIColor.darkGray
        sepiaToneButton.layer.cornerRadius = 5
        view.addSubview(sepiaToneButton)
        
        edgesButton = UIButton(type: .system)
        edgesButton.translatesAutoresizingMaskIntoConstraints = false
        edgesButton.setTitle("Edges", for: .normal)
        edgesButton.addTarget(self, action: #selector(changeFilterToEdges), for: .touchUpInside)
        edgesButton.backgroundColor = UIColor.darkGray
        edgesButton.layer.cornerRadius = 5
        view.addSubview(edgesButton)
        
        eyeDetectionButton = UIButton(type: .system)
        eyeDetectionButton.translatesAutoresizingMaskIntoConstraints = false
        eyeDetectionButton.setTitle("EyeDetection", for: .normal)
        eyeDetectionButton.addTarget(self, action: #selector(changeFilterToEyeDetection), for: .touchUpInside)
        eyeDetectionButton.backgroundColor = UIColor.darkGray
        eyeDetectionButton.layer.cornerRadius = 5
        view.addSubview(eyeDetectionButton)

        filteredImage = UIImageView()
        filteredImage.translatesAutoresizingMaskIntoConstraints = false
        filteredImage.backgroundColor = UIColor.black
        filteredImage.layer.cornerRadius = 15
        filteredImage.clipsToBounds = true
        view.addSubview(filteredImage)
        
        previewImage = UIImageView()
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.backgroundColor = UIColor.black
        previewImage.layer.cornerRadius = 15
        previewImage.clipsToBounds = true
        view.addSubview(previewImage)
        

        NSLayoutConstraint.activate([
            filteredImage.topAnchor.constraint(equalTo:  view.layoutMarginsGuide.topAnchor,
                                               constant: 32),
            filteredImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filteredImage.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor,
                                                  multiplier: 0.40),
            filteredImage.widthAnchor.constraint(equalTo: view.widthAnchor,
                                                 constant: -200),
            
            previewImage.topAnchor.constraint(equalTo: filteredImage.bottomAnchor,
                                              constant: 32),
            previewImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewImage.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor,
                                                 multiplier: 0.40),
            previewImage.widthAnchor.constraint(equalTo: view.widthAnchor,
                                                constant: -200),
            
            edgesButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                constant: -32),
            edgesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            edgesButton.heightAnchor.constraint(equalToConstant: 64),
            edgesButton.widthAnchor.constraint(equalToConstant: 128),
            
            sepiaToneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                    constant: -32),
            sepiaToneButton.rightAnchor.constraint(equalTo: edgesButton.leftAnchor,
                                                   constant: -32),
            sepiaToneButton.heightAnchor.constraint(equalToConstant: 64),
            sepiaToneButton.widthAnchor.constraint(equalToConstant: 128),
            
            eyeDetectionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                       constant: -32),
            eyeDetectionButton.leftAnchor.constraint(equalTo: edgesButton.rightAnchor,
                                                     constant: 32),
            eyeDetectionButton.heightAnchor.constraint(equalToConstant: 64),
            eyeDetectionButton.widthAnchor.constraint(equalToConstant: 128)
        ])
        
        filter = CIFilter(name: "CISepiaTone")!
        filter.setValue(0.0, forKey: kCIInputIntensityKey)
    }
    
    @objc func changeFilterToSepiaTone() {
        filterSepiaState = !filterSepiaState
        filterEdgeState = false
        if !filterSepiaState {
            return
        }
        filter = CIFilter(name: "CISepiaTone")!
        filter.setValue(1.0, forKey: kCIInputIntensityKey)
    }
    
    @objc func changeFilterToEdges() {
        filterEdgeState = !filterEdgeState
        filterSepiaState = false
        if !filterEdgeState {
            return
        }
        filter = CIFilter(name: "CIEdges")!
        filter.setValue(16.0, forKey: kCIInputIntensityKey)
    }
    
    @objc func changeFilterToEyeDetection() {
        eyeDetectionState = !eyeDetectionState
    }

    func loadCamera() {
        cameraSession = AVCaptureSession()
        cameraSession.sessionPreset = AVCaptureSession.Preset.high
        
        guard let currentDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: .front
        ).devices.first else {
            return
        }
                
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            return
        }
        cameraSession.addInput(captureDeviceInput)

        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        previewImage.layer.addSublayer(cameraPreviewLayer!)

        cameraPreviewLayer?.frame = CGRect(x: 0, y: 0,
                                           width: previewImage.frame.width,
                                           height: previewImage.frame.height)
                                           
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraSession.startRunning()
        
        setupInputOutput(currentDevice)
    }

    func setupInputOutput(_ currentDevice: AVCaptureDevice) {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice)
            cameraSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            if cameraSession.canAddInput(captureDeviceInput) {
                cameraSession.addInput(captureDeviceInput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            
            // calls captureOutput
            videoOutput.setSampleBufferDelegate(
                self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if cameraSession.canAddOutput(videoOutput) {
                cameraSession.addOutput(videoOutput)
                print("Camera output added")
            }
            cameraSession.startRunning()
            
        } catch {
            print(error)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        if eyeDetectionState {
            let param: [String:Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            if let faceDetector: CIDetector = CIDetector(ofType: CIDetectorTypeFace,
                                                         context: context, options: param){
                let detectResult = faceDetector.features(in: cameraImage)
                
                let renderer = UIGraphicsImageRenderer(size: cameraImage.extent.size)
                let img = renderer.image { ctx in
                    UIImage(ciImage: cameraImage).draw(at: .zero)
                    for feature in detectResult{
                        let faceFeature: CIFaceFeature = feature as! CIFaceFeature
                        if faceFeature.hasLeftEyePosition{
                            ctx.cgContext.addEllipse(in: CGRect(x: faceFeature.leftEyePosition.x - 25,
                                                                y: cameraImage.extent.size.height -
                                                                    faceFeature.leftEyePosition.y - 25,
                                                                width: 50, height: 50))
                            ctx.cgContext.setStrokeColor(CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
                            ctx.cgContext.drawPath(using: .stroke)
                        }
                        if faceFeature.hasRightEyePosition{
                            ctx.cgContext.addEllipse(in: CGRect(x: faceFeature.rightEyePosition.x - 25,
                                                                y: cameraImage.extent.size.height -
                                                                    faceFeature.rightEyePosition.y - 25,
                                                                width: 50, height: 50))
                            ctx.cgContext.setStrokeColor(CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
                            ctx.cgContext.drawPath(using: .stroke)
                        }
                    }
                }
                cameraImage = CIImage(image: img)!
            }
        }
        var cgImage: CGImage
        
        if filterEdgeState || filterSepiaState {
            filter.setValue(cameraImage, forKey: kCIInputImageKey)
            cgImage = self.context.createCGImage(filter.outputImage!, from: cameraImage.extent)!
        }
        else
        {
            cgImage = self.context.createCGImage(cameraImage, from: cameraImage.extent)!
        }
        cgImage = cgImage.cropping(
            to: CGRect(x: 0,
                       y: (cgImage.height - Int(Double(cgImage.width) * imageAspectRatio)) / 2,
                       width: cgImage.width - 0,
                       height: Int(Double(cgImage.width) * imageAspectRatio)))!

        DispatchQueue.main.async { [self] in
            filteredImage.layer.contentsGravity = .resizeAspectFill
            filteredImage.image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .upMirrored)
        }
    }
}
