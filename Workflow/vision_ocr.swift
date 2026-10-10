import Foundation
import AppKit
import Vision

let args = CommandLine.arguments

if args.count > 1 && args[1] == "--has-image" {
    if let pb = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], !pb.isEmpty {
        exit(0)
    } else {
        exit(1)
    }
}

func getCGImage() -> CGImage? {
    if args.count > 1 && !args[1].hasPrefix("-") {
        let url = URL(fileURLWithPath: args[1])
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            return nil
        }
        return cg
    }
    guard let pb = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
          let img = pb.first else {
        return nil
    }
    var rect = CGRect(origin: .zero, size: img.size)
    return img.cgImage(forProposedRect: &rect, context: nil, hints: nil)
}

guard let cg = getCGImage() else {
    FileHandle.standardError.write(Data("cannot load image\n".utf8))
    exit(1)
}

let req = VNRecognizeTextRequest()
req.recognitionLevel = .accurate
req.usesLanguageCorrection = true
req.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja-JP", "ko-KR"]
let handler = VNImageRequestHandler(cgImage: cg, options: [:])
do {
    try handler.perform([req])
} catch {
    FileHandle.standardError.write(Data("perform failed: \(error)\n".utf8))
    exit(1)
}
var out: [String] = []
for obs in (req.results ?? []) {
    if let c = obs.topCandidates(1).first {
        out.append(c.string)
    }
}
print(out.joined(separator: "\n"))
