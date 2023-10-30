import Foundation
import CoreImage

struct FilterParameters {
    var contrast: Float
    var brightness: Float
    var saturation: Float
    var blur: Float
    var sharpness: Float
}

class FilterManager {
    static func createFilter(filterName: String, inputImage: CIImage?, key: String, filterValue: Float) -> CIImage? {
        guard let inputImage = inputImage, let filter = CIFilter(name: filterName) else {
            fatalError("Invalid filter name or input image is nil")
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: filterValue), forKey: key)
        return filter.outputImage!
    }
}
