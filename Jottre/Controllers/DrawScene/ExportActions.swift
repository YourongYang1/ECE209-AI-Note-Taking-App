//
//  ExportActions.swift
//  Jottre
//
//  Created by Anton Lorani on 16.01.21.
//

import UIKit
import OSLog
import Alamofire

extension DrawViewController {
    
    func createExportToPDFAction() -> UIAlertAction {
        return UIAlertAction(title: "PDF", style: .default, handler: { (action) in
            self.startLoading()
            
            self.drawingToPDF { (data, _, _) in
                
                guard let data = data else {
                    self.stopLoading()
                    return
                }
                                
                let fileURL = Settings.tmpDirectory.appendingPathComponent(self.node.name!).appendingPathExtension("pdf")
                
                if !data.writeToReturingBoolean(url: fileURL) {
                    self.stopLoading()
                    return
                }
                
                let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                
                DispatchQueue.main.async {
                    self.stopLoading()
                    self.presentActivityViewController(activityViewController: activityViewController)
                }
                
            }
            
        })
    }
    
    func createExportToPNGAction() -> UIAlertAction {
        return UIAlertAction(title: "PNG", style: .default, handler: { (action) in
            self.startLoading()

            guard let drawing = self.node.codable?.drawing else {
                self.stopLoading()
                return
            }
            
            var bounds = drawing.bounds
                bounds.size.height = drawing.bounds.maxY + 100
            
            guard let data = drawing.image(from: bounds, scale: 1, userInterfaceStyle: .light).jpegData(compressionQuality: 1) else {
                self.stopLoading()
                return
            }
            
            let bytes = [ UInt8 ](data)
            var bytes_string = String()
            print(bytes)
            for i in bytes{
                if i < 10{
                    bytes_string += "00"
                    bytes_string += String(i)
                    
                }
                else if 10 <= i && i < 100  {
                    bytes_string += "0"
                    bytes_string += String(i)
                }
                else{
                    bytes_string += String(i)
                }
            }
            
            let data2 = Data(bytes: bytes_string, count: bytes_string.count);
            print(NSData(data: data2))
            
            print(NSData(data: data))
            var data_5 = Data()
            AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(data2, withName: "one")
                    multipartFormData.append(Data("p3".utf8), withName: "two")
            }, to: "http://43.156.104.181:5000/image")
                .responseData { response in
                    debugPrint(response.value)
                    if let data_6 = response.value{
                        data_5 = data_6 as! Data
                        let uiimage_1 = UIImage(data: data_5)
                        UIImageWriteToSavedPhotosAlbum(uiimage_1 ?? UIImage(), nil, nil, nil)
                    }
                }
       
  
            let fileURL = Settings.tmpDirectory.appendingPathComponent(self.node.name!).appendingPathExtension("png")
            
            if !data.writeToReturingBoolean(url: fileURL) {
                self.stopLoading()
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            DispatchQueue.main.async {
                self.stopLoading()
                self.presentActivityViewController(activityViewController: activityViewController)
            }
        
        })
    }
    
    func createExportToJPGAction() -> UIAlertAction {
        return UIAlertAction(title: "JPG", style: .default, handler: { (action) in
            self.startLoading()

            guard let drawing = self.node.codable?.drawing else {
                self.stopLoading()
                return
            }
            
            var bounds = drawing.bounds
                bounds.size.height = drawing.bounds.maxY + 100
                bounds.size.width = drawing.bounds.maxX + 20
                bounds.origin = CGPoint(x: drawing.bounds.origin.x-10, y: drawing.bounds.origin.y-10)
            
            guard let data = drawing.image(from: bounds, scale: 1, userInterfaceStyle: .light).jpegData(compressionQuality: 1) else {
                self.stopLoading()
                return
            }

            let bytes = [ UInt8 ](data)
            var bytes_string = String()
            print(bytes)
            for i in bytes{
                if i < 10{
                    bytes_string += "00"
                    bytes_string += String(i)
                    
                }
                else if 10 <= i && i < 100  {
                    bytes_string += "0"
                    bytes_string += String(i)
                }
                else{
                    bytes_string += String(i)
                }
            }
            
            let data2 = Data(bytes: bytes_string, count: bytes_string.count);
            print(NSData(data: data2))
            var data_3 = Data()
            print(NSData(data: data))
            AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(data2, withName: "one")
                    multipartFormData.append(Data("p4".utf8), withName: "two")
            }, to: "http://43.156.104.181:5000/image")
                .responseData { response in
                    debugPrint(response.value)
                    if let data_2 = response.value{
                        data_3 = data_2
                        let uiimage = UIImage(data: data_2)
                        UIImageWriteToSavedPhotosAlbum(uiimage ?? UIImage(), nil, nil, nil)
                    }
                }
            
            let fileURL = Settings.tmpDirectory.appendingPathComponent(self.node.name!).appendingPathExtension("jpg")
            
            if !data.writeToReturingBoolean(url: fileURL) {
                self.stopLoading()
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            DispatchQueue.main.async {
                self.stopLoading()
                self.presentActivityViewController(activityViewController: activityViewController)
            }
            
        })
    }
    
    func createShareAction() -> UIAlertAction {
        return UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { (action) in
            self.startLoading()
            self.node.push()
            
            guard let url = self.node.url else {
                self.stopLoading()
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            DispatchQueue.main.async {
                self.stopLoading()
                self.presentActivityViewController(activityViewController: activityViewController)
            }
            
        })
    }
    
    fileprivate func presentActivityViewController(activityViewController: UIActivityViewController, animated: Bool = true) {
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        self.present(activityViewController, animated: animated, completion: nil)
    }
    
}


