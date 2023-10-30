import Foundation
import CoreImage
import AVFoundation

class ExportVideoManager {
    func applyVideoFilters(inputURL: URL, outputURL: URL, filterValue: FilterParameters, completionHandler: @escaping (URL?, Error?) -> Void) {
        let videoAsset = AVAsset(url: inputURL)
        
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completionHandler(nil, NSError(domain: "YourAppDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create video track"]))
            return
        }
        
        do {
            try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                                           of: videoAsset.tracks(withMediaType: .video)[0],
                                           at: .zero)
        } catch {
            completionHandler(nil, error)
            return
        }
        
        let filterComposition = AVMutableVideoComposition(asset: composition, applyingCIFiltersWithHandler: { request in
            let source = request.sourceImage.clampedToExtent()
            var output: CIImage?

            if let contrastOutput = FilterManager.createFilter(filterName: "CIColorControls", inputImage: source, key: kCIInputContrastKey, filterValue: filterValue.contrast),
               let brightnessOutput = FilterManager.createFilter(filterName: "CIColorControls", inputImage: contrastOutput, key: kCIInputBrightnessKey, filterValue: filterValue.brightness),
               let saturationOutput = FilterManager.createFilter(filterName: "CIColorControls", inputImage: brightnessOutput, key: kCIInputSaturationKey, filterValue: filterValue.saturation),
               let sharpnessOutput = FilterManager.createFilter(filterName: "CISharpenLuminance", inputImage: saturationOutput, key: kCIInputSharpnessKey, filterValue: filterValue.sharpness),
               let blurOutput = FilterManager.createFilter(filterName: "CIGaussianBlur", inputImage: sharpnessOutput, key: kCIInputRadiusKey, filterValue: filterValue.blur) {

                output = blurOutput

            } else {
                print("Error: One of the image outputs is nil")
            }

            if let unwrappedOutput = output {
                request.finish(with: unwrappedOutput, context: nil)
            } else {
                print("Error: Output is nil")
            }
        })

        
        let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        export?.outputFileType = .mov
        export?.outputURL = outputURL
        export?.videoComposition = filterComposition
        
        export?.exportAsynchronously {
            DispatchQueue.main.async {
                if export?.status == .completed {
                    completionHandler(outputURL, nil)
                } else if let error = export?.error {
                    completionHandler(nil, error)
                } else {
                    let exportError = NSError(domain: "YourAppDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to export video"])
                    completionHandler(nil, exportError)
                }
            }
        }
    }
}
