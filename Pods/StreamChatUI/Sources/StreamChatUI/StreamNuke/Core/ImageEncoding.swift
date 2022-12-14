// The MIT License (MIT)
//
// Copyright (c) 2015-2021 Alexander Grebenyuk (github.com/kean).

#if !os(macOS)
import UIKit
#else
import Cocoa
#endif

#if os(watchOS)
import WatchKit
#endif

import ImageIO

// MARK: - ImageEncoding

/// An image encoder.
protocol ImageEncoding {
    /// Encodes the given image.
    func encode(_ image: PlatformImage) -> Data?

    /// An optional method which encodes the given image container.
    func encode(_ container: ImageContainer, context: ImageEncodingContext) -> Data?
}

extension ImageEncoding {
    func encode(_ container: ImageContainer, context: ImageEncodingContext) -> Data? {
        self.encode(container.image)
    }
}

// MARK: - ImageEncoder

/// Image encoding context used when selecting which encoder to use.
struct ImageEncodingContext {
    let request: ImageRequest
    let image: PlatformImage
    let urlResponse: URLResponse?
}

// MARK: - ImageEncoders

/// A namespace with all available encoders.
enum ImageEncoders {}

// MARK: - ImageEncoders.Default

extension ImageEncoders {
    /// A default adaptive encoder which uses best encoder available depending
    /// on the input image and its configuration.
    struct Default: ImageEncoding {
        var compressionQuality: Float

        /// Set to `true` to switch to HEIF when it is available on the current hardware.
        /// `false` by default.
        var isHEIFPreferred = false

        init(compressionQuality: Float = 0.8) {
            self.compressionQuality = compressionQuality
        }

        func encode(_ image: PlatformImage) -> Data? {
            guard let cgImage = image.cgImage else {
                return nil
            }
            let type: ImageType
            if cgImage.isOpaque {
                if isHEIFPreferred && ImageEncoders.ImageIO.isSupported(type: .heic) {
                    type = .heic
                } else {
                    type = .jpeg
                }
            } else {
                type = .png
            }
            let encoder = ImageEncoders.ImageIO(type: type, compressionRatio: compressionQuality)
            return encoder.encode(image)
        }
    }
}

// MARK: - ImageEncoders.ImageIO

extension ImageEncoders {
    /// An Image I/O based encoder.
    ///
    /// Image I/O is a system framework that allows applications to read and
    /// write most image file formats. This framework offers high efficiency,
    /// color management, and access to image metadata.
    struct ImageIO: ImageEncoding {
        let type: ImageType
        let compressionRatio: Float

        /// - parameter format: The output format. Make sure that the format is
        /// supported on the current hardware.s
        /// - parameter compressionRatio: 0.8 by default.
        init(type: ImageType, compressionRatio: Float = 0.8) {
            self.type = type
            self.compressionRatio = compressionRatio
        }

        private static let lock = NSLock()
        private static var availability = [ImageType: Bool]()

        /// Retuns `true` if the encoding is available for the given format on
        /// the current hardware. Some of the most recent formats might not be
        /// available so its best to check before using them.
        static func isSupported(type: ImageType) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if let isAvailable = availability[type] {
                return isAvailable
            }
            let isAvailable = CGImageDestinationCreateWithData(
                NSMutableData() as CFMutableData, type.rawValue as CFString, 1, nil
            ) != nil
            availability[type] = isAvailable
            return isAvailable
        }

        func encode(_ image: PlatformImage) -> Data? {
            let data = NSMutableData()
            let options: NSDictionary = [
                kCGImageDestinationLossyCompressionQuality: compressionRatio
            ]
            guard let source = image.cgImage,
                let destination = CGImageDestinationCreateWithData(
                    data as CFMutableData, type.rawValue as CFString, 1, nil
                ) else {
                    return nil
            }
            CGImageDestinationAddImage(destination, source, options)
            CGImageDestinationFinalize(destination)
            return data as Data
        }
    }
}
