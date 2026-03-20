import UIKit

extension UIImage {
    
    class func createImage(color: UIColor, rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        color.setFill()
        UIRectFill(rect)
        let imageFromContext = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = imageFromContext else {
            fatalError("imageFromContext is nil.")
        }

        return image
    }
    
    /// Image Aspect Ratio(width / height)
    var aspectRatio: CGFloat {
        return size.width / size.height
    }

    func isEqualImage(_ image: UIImage) -> Bool {
        let selfData = self.pngData()
        let otherImage = image.pngData()
        if let selfData = selfData, let otherImage = otherImage {
            return selfData.elementsEqual(otherImage)
        }
        return false
    }

    /// Apply noir effect to images
    func withGrayScaleNoir() -> UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectNoir")
        currentFilter?.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter?.outputImage,
            let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return self
    }

    /// Apply mono effect to images
    func withGrayScaleMono() -> UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectMono")
        currentFilter?.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter?.outputImage,
            let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return self
    }

    /// Apply tonal effect to images
    func withGrayScaleTonal() -> UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectTonal")
        currentFilter?.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter?.outputImage,
            let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return self
    }

    /// Invert color to image
    func withInvert() -> UIImage {
        let context = CIContext(options: nil)

        let beginImage = CIImage(image: self)
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(beginImage, forKey: kCIInputImageKey)
        if let output = filter?.outputImage,
            let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return self
    }

    func tint(tintColor: UIColor) -> UIImage {
        return modifiedImage { context, rect in
            // draw black background - workaround to preserve color of partially transparent pixels
            context.setBlendMode(.normal)
            UIColor.black.setFill()
            context.fill(rect)

            if let cgImage = self.cgImage {
                // draw original image
                context.setBlendMode(.normal)
                context.draw(cgImage, in: rect)
            }

            // tint image (loosing alpha) - the luminosity of the original image is preserved
            context.setBlendMode(.color)
            tintColor.setFill()
            context.fill(rect)

            if let cgImage = self.cgImage {
                // mask by alpha values of original image
                context.setBlendMode(.destinationIn)
                context.draw(cgImage, in: rect)
            }
        }
    }

    func fillAlpha(fillColor: UIColor) -> UIImage {

        return modifiedImage { context, rect in
            // draw tint color
            context.setBlendMode(.normal)
            fillColor.setFill()
            context.fill(rect)

            if let cgImage = self.cgImage {
                // mask by alpha values of original image
                context.setBlendMode(.destinationIn)
                context.draw(cgImage, in: rect)
            }
        }
    }

    private func modifiedImage(draw: (CGContext, CGRect) -> Void) -> UIImage {

        // using scale correctly preserves retina images
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        if let context: CGContext = UIGraphicsGetCurrentContext() {
            // correctly rotate image
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1.0, y: -1.0)

            let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)

            draw(context, rect)

            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? self
        }
        return self
    }

    /**
     More brightness

     - Parameters:
     - value: bright value

     - Return: bright image
     */
    func withBrightness(value: Float) -> UIImage {
        if let aCGImage = self.cgImage {
            let aCIImage = CIImage(cgImage: aCGImage)
            let context = CIContext(options: nil)
            let brightnessFilter = CIFilter(name: "CIColorControls")
            brightnessFilter?.setValue(aCIImage, forKey: "inputImage")
            brightnessFilter?.setValue(value, forKey: "inputBrightness")
            if let outputImage = brightnessFilter?.outputImage,
                let imageRef = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: imageRef)
            }
        }
        return self
    }

    /**
     Crop image

     - Parameters:
     - posX: x-position to starting crop
     - posY: y-position to starting crop
     - width: length of width to cut
     - height: length of height to cut
     - scale: this image's scale

     - Return: croped image
     */
    func cropToBounds(posX: CGFloat, posY: CGFloat,
                      width: CGFloat, height: CGFloat, scale: CGFloat) -> UIImage {
        if let cgImage = self.cgImage {
            let contextImage: UIImage = UIImage(cgImage: cgImage)
            let contextSize: CGSize = contextImage.size
            var imageScale: CGFloat
            var cgPosX: CGFloat = posX
            var cgPosY: CGFloat = posY
            if contextSize.width > contextSize.height {
                imageScale = contextSize.height / height
                cgPosX = posX * imageScale
                cgPosY = posY * imageScale
            } else {
                imageScale = contextSize.width / width
                cgPosY = posY * imageScale
                cgPosX = posX * imageScale
            }

            cgPosX /= scale
            cgPosY /= scale
            let cgWidth: CGFloat = width * imageScale / scale
            let cgHeight: CGFloat = height * imageScale / scale

            let cropRect = CGRect(x: cgPosX, y: cgPosY, width: cgWidth, height: cgHeight)
            UIGraphicsBeginImageContextWithOptions(cropRect.size, true, 1 / imageScale)

            //            UIGraphicsBeginImageContextWithOptions(cropRect.size, false, self.scale)
            let origin = CGPoint(x: cropRect.origin.x * CGFloat(-1), y: cropRect.origin.y * CGFloat(-1))
            self.draw(at: origin)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return result ?? self
        }
        return self
    }

    /**
     Image resize based on the longest length and width
     - Parameters:
     - width: maximum length
     - Return: resized image
     */
    func resize(width: CGFloat) -> UIImage {
        let size = self.size
        if self.size.width > self.size.height {
            if self.size.width > width {
                let newSize = CGSize(width: width, height: width * (size.height / size.width))
                return resize(targetSize: newSize)
            }
        } else {
            if self.size.height > width {
                let newSize = CGSize(width: width * (size.width / size.height), height: width)
                return resize(targetSize: newSize)
            }
        }
        return self
    }

    /**
     Image resize by target size
     - Parameters:
     - targetSize: desired size
     - Return: resized image
     */
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? self
    }


    /**
     Apply blur effect to images

     - Parameters:
     - radius: blur radius

     - Return: blurred image
     */
    func applyBlurEffect(radius: CGFloat) -> UIImage {
        guard let gaussianBlur = CIFilter(name: "CIGaussianBlur") else {
            return self
        }

        if let ciImage = CIImage(image: self) {
            gaussianBlur.setValue(ciImage, forKey: kCIInputImageKey)
            gaussianBlur.setValue(radius, forKey: kCIInputRadiusKey)

            if let result = gaussianBlur.outputImage {
                let ciContext  = CIContext(options: nil)
                let boundingRect = CGRect(x: -radius * 0,
                                          y: -radius * 0,
                                          width: self.size.width + (radius * 0),
                                          height: self.size.height + (radius * 0))

                if let cgImage = ciContext.createCGImage(result, from: boundingRect) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return self
    }
}
