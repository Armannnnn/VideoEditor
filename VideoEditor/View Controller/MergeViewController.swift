import UIKit
import MediaPlayer
import MobileCoreServices
import Photos
import AVFoundation

class MergeVideoViewController: UIViewController {
    var firstAsset: AVAsset?
    var secondAsset: AVAsset?
    var loadingAssetOne = false
    
    private lazy var activityMonitor: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        
        let backgroundColor = UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1)
        view.backgroundColor = backgroundColor
        
        self.title = "Merge"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonPressed))
        backButton.tintColor = .white
        self.navigationItem.leftBarButtonItem = backButton
        let buttonWidth: CGFloat = 343
        let buttonHeight: CGFloat = 48
        
        let loadAssetOneButton = createButton(withTitle: "Load asset one", tag: 0, width: buttonWidth, height: buttonHeight)
        let loadAssetTwoButton = createButton(withTitle: "Load asset two", tag: 1, width: buttonWidth, height: buttonHeight)
        let mergeVideoButton = createButton(withTitle: "Merge", tag: 2, width: buttonWidth, height: buttonHeight)
        
        view.addSubview(activityMonitor)
        view.addSubview(loadAssetOneButton)
        view.addSubview(loadAssetTwoButton)
        view.addSubview(mergeVideoButton)
        
        NSLayoutConstraint.activate([
            activityMonitor.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityMonitor.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            loadAssetOneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadAssetOneButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadAssetOneButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            loadAssetOneButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            loadAssetTwoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadAssetTwoButton.topAnchor.constraint(equalTo: loadAssetOneButton.bottomAnchor, constant: 20),
            loadAssetTwoButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            loadAssetTwoButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            mergeVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mergeVideoButton.topAnchor.constraint(equalTo: loadAssetTwoButton.bottomAnchor, constant: 20),
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
    
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
      activityMonitor.stopAnimating()
      firstAsset = nil
      secondAsset = nil

      guard
        session.status == AVAssetExportSession.Status.completed,
        let outputURL = session.outputURL
        else { return }

      let saveVideoToPhotos = {
      let changes: () -> Void = {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
      }
      PHPhotoLibrary.shared().performChanges(changes) { saved, error in
        DispatchQueue.main.async {
          let success = saved && (error == nil)
          let title = success ? "Success" : "Error"
          let message = success ? "Video saved" : "Failed to save video"

          let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
          alert.addAction(UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.cancel,
            handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
      }

      // Ensure permission to access Photo Library
      if PHPhotoLibrary.authorizationStatus() != .authorized {
        PHPhotoLibrary.requestAuthorization { status in
          if status == .authorized {
            saveVideoToPhotos()
          }
        }
      } else {
        saveVideoToPhotos()
      }
    }

    func savedPhotosAvailable() -> Bool {
      guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        else { return true }

      let alert = UIAlertController(
        title: "Not Available",
        message: "No Saved Album found",
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.cancel,
        handler: nil))
      present(alert, animated: true, completion: nil)
      return false
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            loadAssetOne(sender)
        case 1:
            loadAssetTwo(sender)
        case 2:
            merge(sender)
        default:
            break
        }
    }
    
    @objc func loadAssetOne(_ sender: Any) {
        if savedPhotosAvailable() {
          loadingAssetOne = true
          VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @objc func loadAssetTwo(_ sender: Any) {
        if savedPhotosAvailable() {
          loadingAssetOne = false
          VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @objc func merge(_ sender: Any) {
        guard let firstAsset = firstAsset, let secondAsset = secondAsset else { return }

        activityMonitor.startAnimating()

        let mixComposition = AVMutableComposition()

         guard
           let firstTrack = mixComposition.addMutableTrack(
             withMediaType: .video,
             preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
           else { return }

         do {
           try firstTrack.insertTimeRange(
             CMTimeRangeMake(start: .zero, duration: firstAsset.duration),
             of: firstAsset.tracks(withMediaType: .video)[0],
             at: .zero)
         } catch {
           print("Failed to load first track")
           return
         }

         guard
           let secondTrack = mixComposition.addMutableTrack(
             withMediaType: .video,
             preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
           else { return }

         do {
           try secondTrack.insertTimeRange(
             CMTimeRangeMake(start: .zero, duration: secondAsset.duration),
             of: secondAsset.tracks(withMediaType: .video)[0],
             at: firstAsset.duration)
         } catch {
           print("Failed to load second track")
           return
         }

        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(
            start: .zero,
            duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))

        let firstInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        firstInstruction.setTransform(firstTrack.preferredTransform, at: .zero)

        let secondInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
        secondInstruction.setTransform(secondTrack.preferredTransform, at: .zero)

        let duration = CMTimeMake(value: Int64(0.1), timescale: 10) // Например, задержка в 0.1 секунду
        firstInstruction.setOpacity(0.0, at: firstAsset.duration - duration)


        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = firstTrack.minFrameDuration
        mainComposition.renderSize = firstTrack.naturalSize

        guard let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

        guard let exporter = AVAssetExportSession(
            asset: mixComposition,
            presetName: AVAssetExportPresetHighestQuality) else { return }
        
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition

        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
    }

    }

    extension MergeVideoViewController: UIImagePickerControllerDelegate {
      func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
      ) {
        dismiss(animated: true, completion: nil)

        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
          mediaType == (kUTTypeMovie as String),
          let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
          else { return }

        let avAsset = AVAsset(url: url)
        var message = ""
        if loadingAssetOne {
          message = "Video one loaded"
          firstAsset = avAsset
        } else {
          message = "Video two loaded"
          secondAsset = avAsset
        }
        let alert = UIAlertController(
          title: "Asset Loaded",
          message: message,
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(
          title: "OK",
          style: UIAlertAction.Style.cancel,
          handler: nil))
        present(alert, animated: true, completion: nil)
      }
    }


extension MergeVideoViewController: UINavigationControllerDelegate {
}

extension MergeVideoViewController: MPMediaPickerControllerDelegate {
  func mediaPicker(
    _ mediaPicker: MPMediaPickerController,
    didPickMediaItems mediaItemCollection: MPMediaItemCollection
  ) {
    dismiss(animated: true)
  }

  func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
    dismiss(animated: true, completion: nil)
  }
}

