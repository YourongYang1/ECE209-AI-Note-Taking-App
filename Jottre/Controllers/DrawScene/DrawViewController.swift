//
//  DrawViewController.swift
//  Jottre
//
//  Created by Anton Lorani on 16.01.21.
//

import UIKit
import PencilKit
import OSLog

class DrawViewController: UIViewController, UIIndirectScribbleInteractionDelegate, UIScribbleInteractionDelegate, UITextFieldDelegate {
//class ViewController: UIViewController, UIIndirectScribbleInteractionDelegate, UIScribbleInteractionDelegate, UITextFieldDelegate {
    
    // MARK: - Properties
    //by yinqiu
    
    var stickerPositions: [CGPoint] = [] // added by yinqiu, the positions of these stickerFields
    
    //by tianwen:propertiies of scribble
    var stickerTextFields: [StickerTextField] = []
    
    var stickerContainerView = UIView()
    
    var engravingField = EngravingFakeField()

    // Used to identify the Scribble Element representing the background view.
    let rootViewElementID = UUID()
    
    var node: Node!
    
    var isUndoEnabled: Bool = false
    
    var modifiedCount: Int = 0
        
    var hasModifiedDrawing: Bool = false {
        didSet {
            reloadNavigationItems()
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    

    
    // MARK: - Subviews
    
    var loadingView: LoadingView = {
        return LoadingView()
    }()
    
    var canvasView: PKCanvasView = {
        let canvasView = PKCanvasView()
            canvasView.translatesAutoresizingMaskIntoConstraints = false
            canvasView.drawingPolicy = .default
            canvasView.alwaysBounceVertical = true
            canvasView.maximumZoomScale = 3
            canvasView.backgroundColor = .white
        return canvasView
    }()
    
    var toolPicker: PKToolPicker = {
        return PKToolPicker()
    }()
    
    var redoButton: UIBarButtonItem!
    
    var undoButton: UIBarButtonItem!
    
    
    
    // MARK: - Init
    
    init(node: Node) {
        super.init(nibName: nil, bundle: nil)
        self.node = node
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupDelegates()
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let canvasScale = canvasView.bounds.width / node.codable!.width
        canvasView.minimumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        node.isOpened = true
        
        guard let parent = parent, let window = parent.view.window, let windowScene = window.windowScene else { return }
        
        if let screenshotService = windowScene.screenshotService { screenshotService.delegate = self }
        
        windowScene.userActivity = node.openDetailUserActivity
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.window?.windowScene?.screenshotService?.delegate = nil
        view.window?.windowScene?.userActivity = nil
        
        node.isOpened = false
        
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        view.backgroundColor = (traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? .black : .white

    }
    
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        userActivity!.addUserInfoEntries(from: [ Node.NodeOpenDetailIdKey: node.url! ])
    }
    
    
    
    // MARK: - Methods
    
    func setupViews() {

        traitCollectionDidChange(traitCollection)
            
        view.backgroundColor = (traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? .black : .white
            
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = node.name
        //navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(exportDrawing))

            
        var img=UIImage(named: "handwritten.jpg")
        img=img?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
            
        //let items1=UIBarButtonItem(image: img, style: UIBarButtonItem.Style.plain, target: self, action: #selector(handwriting))
        let items1=UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.compose, target: self, action: #selector(scribble))
        let items2=UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(exportDrawing))
            
        self.navigationItem.rightBarButtonItems=[items2,items1]
        
        reloadNavigationItems()
        
        view.addSubview(canvasView)
        canvasView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        canvasView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        canvasView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(loadingView)
        loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        loadingView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        updateContentSizeForDrawing()
        
    }
    
    
    private func setupDelegates() {
        
        guard let nodeCodable = node.codable else { return }
        
        canvasView.delegate = self
        canvasView.drawing = nodeCodable.drawing
        
        if !UIDevice.isLimited() {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            updateLayout(for: toolPicker)
            canvasView.becomeFirstResponder()
        }
        
    }
 
    
    func updateContentSizeForDrawing() {
        
        let drawing = canvasView.drawing
        let contentHeight: CGFloat

        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + 500) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: node.codable!.width * canvasView.zoomScale, height: contentHeight)
        
    }
    
    
    @objc func exportDrawing() {
        
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        
        let alertTitle = NSLocalizedString("Export note", comment: "")
        let alertCancelTitle = NSLocalizedString("Cancel", comment: "")
        
        let alertController = UIAlertController(title: alertTitle, message: "", preferredStyle: .actionSheet)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        alertController.addAction(createExportToPDFAction())
        alertController.addAction(createExportToJPGAction())
        alertController.addAction(createExportToPNGAction())
        alertController.addAction(createShareAction())
        alertController.addAction(UIAlertAction(title: alertCancelTitle, style: .cancel, handler: { (action) in
            self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
        }))
        
        present(alertController, animated: true, completion: nil)
        
    }

    //handwriting
    /*
    @objc func handwriting() {
            
        toolPicker.setVisible(false, forFirstResponder: canvasView)
            
        let alertTitle = NSLocalizedString("Save note as", comment: "")
        let alertCancelTitle = NSLocalizedString("Cancel", comment: "")
            
        let alertController = UIAlertController(title: alertTitle, message: "", preferredStyle: .actionSheet)

        if let popoverController = alertController.popoverPresentationController {
                popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
            }
            
            //alertController.addAction(createExportToPDFAction())
        alertController.addAction(createExportToJPGAction())
        alertController.addAction(createExportToPNGAction())
        //alertController.addAction(createShareAction())
        alertController.addAction(UIAlertAction(title: alertCancelTitle, style: .cancel, handler: { (action) in self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
            }))
            
        present(alertController, animated: true, completion: nil)
            
        }
     */
    
    //by tianwen
    @objc func scribble() {
        
        //let scribbleController = scribbleViewController()
        //navigationController?.pushViewController(scribbleController, animated: true)
        // The sticker container view provides the writing area to add new
        // stickers over the background, and has the Scribble interactions.
        stickerContainerView.frame = view.bounds
        stickerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(stickerContainerView)
        
        // Install a UIScribbleInteraction, which we'll use to disable Scribble
        // when we want to let the Pencil draw instead of write.
        let scribbleInteraction = UIScribbleInteraction(delegate: self)
        stickerContainerView.addInteraction(scribbleInteraction)

        // Install a UIIndirectScribbleInteraction, which will provide the
        // "elements" that represent virtual writing areas.
        let indirectScribbleInteraction = UIIndirectScribbleInteraction(delegate: self)
        stickerContainerView.addInteraction(indirectScribbleInteraction)
        
        // Background tap recognizer.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        view.addGestureRecognizer(tapGesture)
        
        }
    
    
    @objc func writeDrawingHandler() {
        
        node.inConflict { (conflict) in
            
            if !conflict {
                Logger.main.info("Files not in conflict")
                self.writeDrawing()
                return
            }

            Logger.main.warning("Files in conflict")
            
            DispatchQueue.main.async {

                let alertTitle = NSLocalizedString("File conflict found", comment: "")
                let alertMessage = String(format: NSLocalizedString("The file could not be saved. It seems that the original file (%s.jot) on the disk has changed. (Maybe it was edited on another device at the same time?). Use one of the following options to fix the problem.", comment: "File conflict found (What happened, How to fix)"), self.node.name ?? "?")
                let alertActionOverwriteTitle = NSLocalizedString("Overwrite", comment: "")
                let alertActionCloseTitle = NSLocalizedString("Close without saving", comment: "")
                let alertCancelTitle = NSLocalizedString("Cancel", comment: "")

                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: alertActionOverwriteTitle, style: .destructive, handler: { (action) in
                    self.writeDrawing()
                }))
                alertController.addAction(UIAlertAction(title: alertActionCloseTitle, style: .destructive, handler: { (action) in
                    self.navigationController?.popViewController(animated: true)
                }))
                alertController.addAction(UIAlertAction(title: alertCancelTitle, style: .cancel, handler: nil))

                self.present(alertController, animated: true, completion: nil)
                
            }

        }
        
    }
    
    func writeDrawing() {
        DispatchQueue.main.async {
            let practiceScale: CGFloat = 0.6 // added by yinqiu, the font size
            let textGenerator = TextGenerator()
            //var total_text = ""
            var index = 0
            if !self.stickerTextFields.isEmpty{
                for i in self.stickerTextFields{
                    //print("the textfiled is", type(of: i.text)) //added by yqliu
                    //self.stickerPositions[index]
                    self.canvasView.drawing.append(textGenerator.synthesizeTextDrawing(text: i.text ?? "", practiceScale: practiceScale, lineWidth: self.view.bounds.width, position: self.stickerPositions[index]))
                    index += 1
                }
            }
            self.hasModifiedDrawing = false
            self.node.setDrawing(drawing: self.canvasView.drawing)
        }
    }
//
    // MARK: - UIScribbleInteractionDelegate
    
    func scribbleInteraction(_ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint) -> Bool {
        
        // Disable writing over the logo at the center of the image.
        let midX = view.bounds.midX
        let midY = view.bounds.midY
        let nonWritableWidth = 0.00000001
        let nonWritableHeight = 0.00000001
        let centerRect = CGRect(x: midX, y: midY, width: 0.0, height: 0.0).insetBy(dx: -nonWritableWidth, dy: -nonWritableHeight)
        print("in function 1")
        return !centerRect.contains(location)
    }
    
    // MARK: - UIIndirectScribbleInteractionDelegate
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, shouldDelayFocusForElement elementIdentifier: UUID) -> Bool {
        // When writing on a blank area, wait until the user stops writing
        // before triggering element focus, to avoid writing distractions.
        print("in function 2")
        return elementIdentifier == rootViewElementID
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, requestElementsIn rect: CGRect, completion: @escaping ([ElementIdentifier]) -> Void) {

        var availableElementIDs: [UUID] = []

        // Include the identifier of the root view. It must be at the start of
        // the array, so it doesn't cover all the other fields.
        availableElementIDs.append(rootViewElementID)
        
        // Include the text fields that intersect the requested rect.
        // Even though these are real text fields, Scribble can't find them
        // because it doesn't traverse subviews of a view that has a
        // UIIndirectScribbleInteraction.
        for stickerField in stickerTextFields {
            if stickerField.writableFrame.intersects(rect) {
                availableElementIDs.append(stickerField.identifier)
            }
        }

        // Call the completion handler with the array of element identifiers.
        completion(availableElementIDs)
        print("in function 3")
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, isElementFocused elementIdentifier: UUID) -> Bool {
        if elementIdentifier == rootViewElementID {
            // The root element represents the background view, so it never
            // becomes focused itself.
            return false
        } else {
            // For sticker elements, indicate if the corresponding text field
            // is first responder.
            print("in function 4")
            return stickerFieldForIdentifier(elementIdentifier)?.isFirstResponder ?? false
        }
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, frameForElement elementIdentifier: UUID) -> CGRect {
        var elementRect = CGRect.null
        
        if let stickerField = stickerFieldForIdentifier(elementIdentifier) {
            // Scribble is asking about the frame for one of the sticker frames.
            // Return a frame larger than the field itself to make it easier to
            // append text without creating another field.
            elementRect = stickerField.writableFrame
        } else if elementIdentifier == rootViewElementID {
            // Scribble is asking about the background writing area. Return the
            // frame for the whole view.
            elementRect = stickerContainerView.frame
        }
        print("in function 5")
        return elementRect
    }
        
    func indirectScribbleInteraction(_ interaction: UIInteraction, focusElementIfNeeded elementIdentifier: UUID,
                                     referencePoint focusReferencePoint: CGPoint, completion: @escaping ((UIResponder & UITextInput)?) -> Void) {

        // Get an existing field at this location, or create a new one if
        // writing in the background.
        let stickerField: StickerTextField?
        if elementIdentifier == rootViewElementID {
            stickerField = addStickerFieldAtLocation(focusReferencePoint)
        } else {
            stickerField = stickerFieldForIdentifier(elementIdentifier)
        }

        // Focus the field. It should have no effect if it was focused already.
        stickerField?.becomeFirstResponder()
        
        // Call the completion handler as expected by the caller.
        // It could be called asynchronously if, for example, there was an
        // animation to insert a new sticker field.
        completion(stickerField)
        print("in function 6")
    }
    
    // MARK: - Text Field Event Handling
            
    @objc
    func handleTextFieldDidChange(_ textField: UITextField) {

        guard let stickerField = textField as? StickerTextField else {
            return
        }
 
        // When erasing the entire text of a sticker, remove the corresponding
        // text field.
        if !removeIfEmpty(stickerField) {
            // The size updates to accommodate the current content.
            stickerField.updateSize()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let stickerField = textField as? StickerTextField else {
            return
        }
        removeIfEmpty(stickerField)
    }
    
    // MARK: - Gesture Handling
    
    @objc
    func handleTapGesture() {
        // Unfocus our text fields.
        for stickerField in stickerTextFields where stickerField.isFirstResponder {
            stickerField.resignFirstResponder()
            break
        }
        engravingField.finishEditing()
    }
    
    // MARK: - Sticker Text Field Handling
    
    func stickerFieldForIdentifier(_ identifier: UUID) -> StickerTextField? {
        for stickerField in stickerTextFields where stickerField.identifier == identifier {
            print("in function 7")
            return stickerField
        }
        return nil
    }
    
    func addStickerFieldAtLocation(_ location: CGPoint) -> StickerTextField {

        let stickerField = StickerTextField(origin: location)
        stickerField.delegate = self
        stickerField.addTarget(self, action: #selector(handleTextFieldDidChange(_:)), for: .editingChanged)
        stickerTextFields.append(stickerField)
        self.hasModifiedDrawing = true //added by yinqiu, 2022/2/20
        stickerContainerView.addSubview(stickerField)
        stickerPositions.append(location) //added by yinqiu
        print("in function 8")
        reloadNavigationItems()
        return stickerField
    }

    func remove(stickerField: StickerTextField) {
        if let index = stickerTextFields.firstIndex(of: stickerField) {
            stickerTextFields.remove(at: index)
        }
        stickerField.resignFirstResponder()
        stickerField.removeFromSuperview()
        print("in function 9")
    }
    
    @discardableResult
    func removeIfEmpty(_ stickerField: StickerTextField) -> Bool {
        let textLength = stickerField.text?.count ?? 0
        if textLength == 0 {
            remove(stickerField: stickerField)
            return true
        }
        return false
    }

}
