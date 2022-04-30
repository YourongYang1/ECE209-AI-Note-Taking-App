//
//  MenuActions.swift
//  Jottre
//
//  Created by Anton Lorani on 16.01.21.
//

import UIKit
import OSLog

extension InitialViewController {
    
    func createEditAction(indexPath: IndexPath) -> UIAction {
        
        let localizedAlertActionTitle = NSLocalizedString("Edit", comment: "")
        
        return UIAction(title: localizedAlertActionTitle, image: UIImage(systemName: "square.and.pencil")) { (action) in
            self.collectionView.delegate?.collectionView?(self.collectionView, didSelectItemAt: indexPath)
        }
    }
    
    
    func createRenameAction(indexPath: IndexPath) -> UIAction {
        
        let localizedAlertTitle = NSLocalizedString("Rename note", comment: "")
        
        let localizedAlertMessage = NSLocalizedString("Enter the name and subject for the selected note", comment: "")
        
        let localizedAlertPrimaryActionTitle = NSLocalizedString("Rename", comment: "")
        
        let localizedAlertSecondaryActionTitle = NSLocalizedString("Cancel", comment: "")
        
        return UIAction(title: localizedAlertPrimaryActionTitle, image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { (action) in
            
            guard let currentName = self.nodeCollector.nodes[indexPath.row].name, let url = self.nodeCollector.nodes[indexPath.row].url else {
                return
            }
            
            let alertController = UIAlertController(title: localizedAlertTitle, message: localizedAlertMessage, preferredStyle: .alert)
            
            let name_and_subject = currentName.components(separatedBy: "_")
                        
            alertController.addTextField { (textField) in
                textField.placeholder = "Name:" + name_and_subject[0]
            }
            // added by yinqiu, 2022/2/20
            alertController.addTextField { (textField) in
                textField.placeholder = "Subject:" + name_and_subject[1]
            }
                        
            alertController.addAction(UIAlertAction(title: localizedAlertPrimaryActionTitle, style: UIAlertAction.Style.default, handler: { (action) in
                
                guard let textFields = alertController.textFields, var updatedName = textFields[0].text else {
                    return
                }
                guard let textFields = alertController.textFields, let updatedSubject = textFields[1].text else {
                    return
                }
                updatedName = updatedName + "_" + updatedSubject
                
                self.nodeCollector.nodes[indexPath.row].rename(to: NodeCollector.computeCopyName(baseName: updatedName, path: url.deletingLastPathComponent()))
                
            }))
            alertController.addAction(UIAlertAction(title: localizedAlertSecondaryActionTitle, style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
    
    
    func createDeleteAction(indexPath: IndexPath) -> UIMenu {
        let (title, image) = (NSLocalizedString("Delete", comment: ""), UIImage(systemName: "trash"))
        
        let confirmDeleteAction = UIAction(title: "\(title)?", image: image, attributes: .destructive) { (action) in
                        
            self.nodeCollector.nodes[indexPath.row].delete()
            
        }
        
        return UIMenu(title: title, image: image, options: .destructive, children: [confirmDeleteAction])
    }
    
}
