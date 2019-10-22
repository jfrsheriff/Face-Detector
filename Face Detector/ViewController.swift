//
//  ViewController.swift
//  Face Detector
//
//  Created by Jaffer Sheriff U on 22/10/19.
//  Copyright © 2019 Jaffer Sheriff U. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    private lazy var imgView : UIImageView = {
        let imageView = UIImageView.init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        
        let superView = self.view!
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: superView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: superView.bottomAnchor)
            ])
        
        return imageView
    }()
    
    private lazy var cameraImgPicker : UIImagePickerController = {
        let imagePicker = UIImagePickerController.init()
        imagePicker.sourceType = .camera
        imagePicker.cameraFlashMode = .off
        imagePicker.cameraDevice = .front
        imagePicker.delegate = self
        return imagePicker
    }()
    
    private lazy var galleryImgPicker : UIImagePickerController = {
        let imagePicker = UIImagePickerController.init()
        imagePicker.sourceType = .photoLibrary
        //         imagePicker.cameraCaptureMode = .photo
        imagePicker.delegate = self
        return imagePicker
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        let containerView = UIView.init()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(containerView, aboveSubview: imgView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 0),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor)
            ])
        
        
        let openCameraButton = UIButton()
        openCameraButton.translatesAutoresizingMaskIntoConstraints = false
        openCameraButton.setTitle("Open Camera", for: .normal)
        openCameraButton.addTarget(self, action:#selector(openCameraButtonAction) , for: .touchUpInside)
        openCameraButton.backgroundColor = .gray
        containerView.addSubview(openCameraButton)
        
        NSLayoutConstraint.activate([
            openCameraButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            openCameraButton.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
            openCameraButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            openCameraButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
            ])
        
        
        let openGalleryButton = UIButton()
        openGalleryButton.translatesAutoresizingMaskIntoConstraints = false
        openGalleryButton.setTitle("Open Gallery", for: .normal)
        openGalleryButton.addTarget(self, action:#selector(openGalleryButtonAction) , for: .touchUpInside)
        openGalleryButton.backgroundColor = .gray
        containerView.addSubview(openGalleryButton)
        
        NSLayoutConstraint.activate([
            openGalleryButton.topAnchor.constraint(equalTo: openCameraButton.bottomAnchor, constant: 50),
            openGalleryButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            openGalleryButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            openGalleryButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
            ])
        
        // Do any additional setup after loading the view.
    }
    
    @objc func openCameraButtonAction (){
        self.present(cameraImgPicker, animated: true, completion: nil)
    }
    
    @objc func openGalleryButtonAction (){
        self.present(galleryImgPicker, animated: true, completion: nil)
    }
}

extension ViewController : UIImagePickerControllerDelegate&UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var isFaceDetectionSuccessful = false
        if let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage), let cgImg = image.cgImage {
            
            self.imgView.image = image
            let requestHandler = VNImageRequestHandler(cgImage: cgImg, orientation: self.convertImageOrientation(orientation: image.imageOrientation))
            let request = VNDetectFaceRectanglesRequest { (request, error) in
                
                if let _ = error{
                    print(error.debugDescription)
                    
                } else {
                    if let results = request.results as? [VNFaceObservation], results.count>0 {
                        
                        var currentImage = image
                        for result in results {
                            print("Found a face at \(result.boundingBox.origin)")
                            
                            UIGraphicsBeginImageContextWithOptions(currentImage.size, false, 1.0)
                            currentImage.draw(in: CGRect(x: 0, y: 0, width: currentImage.size.width, height: currentImage.size.height))
                            
                            //get face rect
                            let rect=result.boundingBox
                            let tf=CGAffineTransform.init(scaleX: 1, y: -1).translatedBy(x: 0, y: -currentImage.size.height)
                            let ts=CGAffineTransform.identity.scaledBy(x: currentImage.size.width, y: currentImage.size.height)
                            let converted_rect=rect.applying(ts).applying(tf)
                            
                            //draw face rect on image
                            let c=UIGraphicsGetCurrentContext()!
                            c.setStrokeColor(UIColor.red.cgColor)
                            c.setLineWidth(0.01*currentImage.size.width)
                            c.stroke(converted_rect)
                            
                            //get result image
                            let result=UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            currentImage = result!
                        }
                        isFaceDetectionSuccessful = true
                        self.imgView.image = currentImage
                    }
                }
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
            
        }
        
        picker.dismiss(animated: true) {
            self.showFaceDetectedAlert(isSuccessFul: isFaceDetectionSuccessful)
        }
    }
    
    
    func convertImageOrientation(orientation: UIImage.Orientation) -> CGImagePropertyOrientation  {
        let cgiOrientations : [ CGImagePropertyOrientation ] = [
            .up, .down, .left, .right, .upMirrored, .downMirrored, .leftMirrored, .rightMirrored
        ]
        
        return cgiOrientations[orientation.rawValue]
    }
    
    func showFaceDetectedAlert (isSuccessFul : Bool) {
        var title = "Failure"
        var msg = "No Face Detected"
        if isSuccessFul{
            title = "Success"
            msg = "Face Detected Successfully"
        }
        
        let alertController = UIAlertController.init(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "Ok", style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
}

