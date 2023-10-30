import UIKit
import MobileCoreServices
import Photos

protocol VideoSelectionDelegate: AnyObject {
    func didSelectVideo(at url: URL)
}

class HomeViewController: UIViewController, VideoSelectionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        title = "Video Editor"
        let backgroundColor = UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor : UIColor.white ]
        view.backgroundColor = backgroundColor
        setupButtons()
    }
    
    func setupButtons() {
        let buttonWidth: CGFloat = 343
        let buttonHeight: CGFloat = 48
        
        let uploadVideoButton = createButton(withTitle: "Upload Video", tag: 0, width: buttonWidth, height: buttonHeight)
        let recordVideoButton = createButton(withTitle: "Record Video", tag: 1, width: buttonWidth, height: buttonHeight)
        let mergeVideoButton = createButton(withTitle: "Merge Video", tag: 2, width: buttonWidth, height: buttonHeight)
        
        view.addSubview(uploadVideoButton)
        view.addSubview(recordVideoButton)
        view.addSubview(mergeVideoButton)
        
        NSLayoutConstraint.activate([
            uploadVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadVideoButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            uploadVideoButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            uploadVideoButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            recordVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordVideoButton.topAnchor.constraint(equalTo: uploadVideoButton.bottomAnchor, constant: 20),
            recordVideoButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            recordVideoButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            mergeVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mergeVideoButton.topAnchor.constraint(equalTo: recordVideoButton.bottomAnchor, constant: 20),
            mergeVideoButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            mergeVideoButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
    }
    
    
    func createButton(withTitle title: String, tag: Int, width: CGFloat, height: CGFloat) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        return button
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        if sender.tag == 0 {
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        } else if sender.tag == 1 {
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .camera)
        } else{
            navigationController?.pushViewController(MergeVideoViewController(), animated: true)
        }
    }
    
    func didSelectVideo(at url: URL) {
        let editViewController = EditViewController()
        editViewController.selectedVideoURL = url
        navigationController?.pushViewController(editViewController, animated: true)
    }
}

extension HomeViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let mediaType = info[.mediaType] as? String, mediaType == (kUTTypeMovie as String), let url = info[.mediaURL] as? URL else {
            return
        }
        
        picker.dismiss(animated: true) {
        }
        
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            didSelectVideo(at: videoURL)
        }
    }

}
