//
//  NodeCell.swift
//  Jottre
//
//  Created by Anton Lorani on 16.01.21.
//

import UIKit
var the_map_between_subject_and_color = [String: UIColor]()

class NodeCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var node: Node! {
        didSet {
            
            titleLabel.text = node?.name
            updateMeta()
            
        }
    }
    
    
    var name_with_subject: String?
    {
        didSet{
            let name_and_subject = name_with_subject?.components(separatedBy: "_")
            let dictKeys = [String](the_map_between_subject_and_color.keys)
            print(dictKeys)
            if dictKeys.contains(name_and_subject?[1] ?? "")
            {
                overlay.backgroundColor = the_map_between_subject_and_color[name_and_subject?[1] ?? ""]
            }
            else{
                let color: UIColor = UIColor.init(red: (((CGFloat)((arc4random() % 256)) / 255.0)),green: (((CGFloat)((arc4random() % 256)) / 255.0)),blue: (((CGFloat)((arc4random() % 256)) / 255.0)),alpha: 1.0)
                the_map_between_subject_and_color[name_and_subject?[1] ?? ""] = color
                overlay.backgroundColor = color
            }

        }
    }
    
    // MARK: - Subviews
    
    var titleLabel: UILabel = {
        let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Label"
            label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        return label
    }()
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.roundCorners(corners: [.topLeft, .topRight], radius: 15)
        return imageView
    }()
    
    var overlay: UIView = {
        let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor.systemGray5
            //view.backgroundColor = UIColor.systemGray5
            view.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 15)
        return view
    }()
    
    
    
    // MARK: - Override methods
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        setupViews()

    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        backgroundColor = traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark ? UIColor.secondarySystemBackground : UIColor.systemBackground
    
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        titleLabel.text = nil
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        overlay.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 15)
        imageView.roundCorners(corners: [.topLeft, .topRight], radius: 15)

    }
    
    
    
    // MARK: - Methods
    
    func setupViews() {
        
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        alpha = 0
        
        backgroundColor = traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark ? UIColor.secondarySystemBackground : UIColor.systemBackground
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shadowOpacity = 0.05
        
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 15
        layer.cornerRadius = 15
        
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(overlay)
        overlay.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        overlay.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        overlay.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        overlay.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        
        overlay.addSubview(titleLabel)
        titleLabel.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -15).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: overlay.leftAnchor, constant: 15).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: overlay.rightAnchor, constant: -15).isActive = true
        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        
        UIView.animate(withDuration: 0.4) {
            self.transform = .identity
            self.alpha = 1
        }
        
    }
 
    
    func updateMeta() {

        let thumbnailGenerator = ThumbnailGenerator(size: frame.size)
        thumbnailGenerator.execute(for: node) { (success, thumbnail) in
            if success {
                DispatchQueue.main.async {
                    self.imageView.image = thumbnail
                }
            }
        }
        
    }
    
}


extension NodeCell: NodeObserver {
    
    func didUpdate(node: Node) {
        updateMeta()
    }
    
}
