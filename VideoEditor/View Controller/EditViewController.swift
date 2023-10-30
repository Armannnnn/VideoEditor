import UIKit
import Photos
import AVFoundation
import CoreImage

class EditViewController: UIViewController, VideoSelectionDelegate, FilterSelectionDelegate {
    
    func didSelectFilter(at index: Int) {
        contrastSlider.isHidden = index != 0
        brightnessSlider.isHidden = index != 1
        saturationSlider.isHidden = index != 2
        blurSlider.isHidden = index != 3
        sharpnessSlider.isHidden = index != 4
    }
    
    func didSelectVideo(at url: URL) {
        selectedVideoURL = url
        setupVideoPlayer()
        
    }
    
    let exportVideoManager = ExportVideoManager()

    var player: AVPlayer?
    var playerItemVideoOutput: AVPlayerItemVideoOutput!
    var displayLink: CADisplayLink!
    var selectedVideoURL: URL?
    var contrastSlider: UISlider!
    var brightnessSlider: UISlider!
    var saturationSlider: UISlider!
    var blurSlider: UISlider!
    var sharpnessSlider: UISlider!
    
    let videoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let filtersCollectionView: FilterCollectionView = {
        let collectionView = FilterCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filtersCollectionView.filterDelegate = self
        
        setupUI()
        setupVideoPlayer()

        
    }
    
    func setupUI(){
        
        title = "Edit"
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor : UIColor.white ]
        
        let backgroundColor = UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1)
        view.backgroundColor = backgroundColor
        
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonTapped))
        self.navigationItem.rightBarButtonItem = saveButton
        saveButton.tintColor = .white
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonPressed))
        backButton.tintColor = .white
        self.navigationItem.leftBarButtonItem = backButton
        
        contrastSlider = createSlider(minValue: 0.0, maxValue: 2.0, initialValue: 1.0)
        brightnessSlider = createSlider(minValue: -1.0, maxValue: 1.0, initialValue: 0.0)
        saturationSlider = createSlider(minValue: 0.0, maxValue: 2.0, initialValue: 1.0)
        blurSlider = createSlider(minValue: 0.0, maxValue: 10.0, initialValue: 0.0)
        sharpnessSlider = createSlider(minValue: -5.0, maxValue: 5.0, initialValue: 0.0)
        
        view.addSubview(videoView)
        view.addSubview(contrastSlider)
        view.addSubview(brightnessSlider)
        view.addSubview(saturationSlider)
        view.addSubview(blurSlider)
        view.addSubview(sharpnessSlider)
        view.addSubview(filtersCollectionView)
        
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.heightAnchor.constraint(equalToConstant: 400),
            
            contrastSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contrastSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contrastSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            
            sharpnessSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sharpnessSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sharpnessSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            
            brightnessSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            brightnessSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            brightnessSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            
            saturationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saturationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saturationSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            
            blurSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            blurSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            blurSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            
            filtersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filtersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filtersCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            filtersCollectionView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
    }
    
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func createSlider(minValue: Float, maxValue: Float, initialValue: Float) -> UISlider {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = initialValue
        slider.isHidden = true
        
        return slider
    }
    
    
    func setupVideoPlayer() {
        
        let videoItem = AVPlayerItem(url: selectedVideoURL!)
        self.player = AVPlayer(playerItem: videoItem)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        
        player?.play()
        
        playerItemVideoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
        videoItem.add(playerItemVideoOutput)
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired(link:)))
        displayLink.add(to: .main, forMode: .common)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
    }
    
    @objc func playerDidFinishPlaying(_ notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
            player?.play()
        }
    }
    
    
    @objc func displayLinkFired(link: CADisplayLink) {
        let currentTime = playerItemVideoOutput.itemTime(forHostTime: CACurrentMediaTime())
        if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime) {
            if let buffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
                var frameImage = CIImage(cvPixelBuffer: buffer)
                
                if  let contrastFilter = FilterManager.createFilter(filterName: "CIColorControls", inputImage: frameImage, key: kCIInputContrastKey, filterValue: contrastSlider.value),
                    let brightnessFilter = FilterManager.createFilter(filterName: "CIColorControls", inputImage: contrastFilter, key: kCIInputBrightnessKey, filterValue: brightnessSlider.value),
                    let saturationFilter = FilterManager.createFilter(filterName: "CIColorControls", inputImage: brightnessFilter, key: kCIInputSaturationKey, filterValue: saturationSlider.value),
                    let sharpnessFilter = FilterManager.createFilter(filterName: "CISharpenLuminance", inputImage: saturationFilter, key: kCIInputSharpnessKey, filterValue: sharpnessSlider.value),
                    let blurFilter = FilterManager.createFilter(filterName: "CIGaussianBlur", inputImage: sharpnessFilter, key: kCIInputRadiusKey, filterValue: blurSlider.value) {

                    frameImage = blurFilter

                } else {
                    print("Error: One of the image outputs is nil")
                }
                
                let ciContext = CIContext()
                if let cgImage = ciContext.createCGImage(frameImage, from: frameImage.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self.videoView.layer.contents = uiImage.cgImage
                    }
                }
            }
        }
    }
    
    @objc func saveButtonTapped() {
        guard let selectedVideoURL = selectedVideoURL else {
            return
        }
        
        let videoAsset = AVAsset(url: selectedVideoURL)
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let uniqueFileName = ProcessInfo.processInfo.globallyUniqueString
        let tempOutputURL = tempDirectory.appendingPathComponent("\(uniqueFileName).mov")
        
        let filterParameters = FilterParameters(contrast: contrastSlider.value, brightness: brightnessSlider.value, saturation: saturationSlider.value, blur: blurSlider.value, sharpness: sharpnessSlider.value)
        
        exportVideoManager.applyVideoFilters(inputURL: selectedVideoURL, outputURL: tempOutputURL, filterValue: filterParameters) { filteredURL, error in
            guard let filteredURL = filteredURL, error == nil else {
                return
            }
            
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: filteredURL)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                self.showAlert(message: "Video saved")
                            } else if let error = error {
                                self.showAlert(message: "Unable to save video: \(error.localizedDescription)")
                            }
                        }
                    }
                case .denied, .restricted:
                    DispatchQueue.main.async {
                        self.showAlert(message: "Unable to save video: Access to photo library denied")
                    }
                case .notDetermined:
                    DispatchQueue.main.async {
                        self.showAlert(message: "Unable to save video: Access to photo library not determined")
                    }
                @unknown default:
                    break
                }
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
