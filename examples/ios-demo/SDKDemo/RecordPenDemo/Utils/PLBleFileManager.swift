import Foundation

class PLBleFileManager {
    static let shared = PLBleFileManager()
    private var fileHandles: [String: FileHandle] = [:]
    private let queue = DispatchQueue(label: "com.plaud.blefilemanager", qos: .userInitiated)

    private init() {}

    func saveBleFile(filePath: String, fileName: String, start: Int, data: Data) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let fullPath = (filePath as NSString).appendingPathComponent(fileName)
            let key = fullPath

            do {
                // If first time writing, create file
                if start == 0 {
                    try data.write(to: URL(fileURLWithPath: fullPath))
                    if let handle = FileHandle(forWritingAtPath: fullPath) {
                        self.fileHandles[key] = handle
                    }
                } else {
                    // Get or create file handle
                    var handle = self.fileHandles[key]
                    if handle == nil {
                        handle = FileHandle(forWritingAtPath: fullPath)
                        self.fileHandles[key] = handle
                    }

                                          // Write data
                    if let handle = handle {
                        handle.seek(toFileOffset: UInt64(start))
                        handle.write(data)
                    }
                }
            } catch {
                debugPrint(String(format: NSLocalizedString("file.manager.error.save_failed", comment: ""), error.localizedDescription))
            }
        }
    }

    func closeFile(filePath: String, fileName: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let fullPath = (filePath as NSString).appendingPathComponent(fileName)
            let key = fullPath

            if let handle = self.fileHandles[key] {
                handle.closeFile()
                // self.fileHandles.removeValue(forKey: key)
            }
        }
    }

    func closeAllFiles() {
        queue.async { [weak self] in
            guard let self = self else { return }

            for (_, handle) in self.fileHandles {
                handle.closeFile()
            }
            // self.fileHandles.removeAll()
        }
    }

    func convertAllFilesToPcm() {
        for (path, _) in fileHandles {
            let originalURL = URL(fileURLWithPath: path)
            let modifiedURL = originalURL
                .deletingPathExtension() //
                .appendingPathExtension("pcm")

            convertOpusToPcmPath(inputPath: path, outputPath: modifiedURL.path) { _ in
            }
        }
    }

    func convertAllFilesToMp3(callback: @escaping (Bool, String) -> Void) {
        for (path, _) in fileHandles {
            let originalURL = URL(fileURLWithPath: path)
            let originalURLMP3 = URL(fileURLWithPath: path)

            let modifiedURL = originalURL
                .deletingPathExtension() //
                .appendingPathExtension("pcm")

            let modifiedURLMP3 = originalURLMP3
                .deletingPathExtension() //
                .appendingPathExtension("mp3")

            convertPcmToMp3Path(inputPath: modifiedURL.path, outputPath: modifiedURLMP3.path) { success, msg in
                callback(success, msg)
            }
        }
    }

    private func convertPcmToMp3Path(inputPath: String, outputPath: String, callback: @escaping (Bool, String) -> Void) {
        DispatchQueue.global().async {
            if FileManager.default.fileExists(atPath: outputPath) {
                callback(false, NSLocalizedString("file.manager.error.file_exists", comment: ""))
                return
            }

            JXFileDecoder.shared.convertPcmToMp3Cancel()

            JXFileDecoder.shared.pcmToMp3(pcmPath: inputPath, mp3Path: outputPath) { isFinished, progress in
                if progress == 100, isFinished {
                    callback(true, NSLocalizedString("file.manager.status.transcode_success", comment: ""))
                } else {
                    callback(false, NSLocalizedString("file.manager.status.transcode_failed", comment: ""))
                }
            }
        }
    }

    private func convertOpusToPcmPath(inputPath: String, outputPath: String, callback: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            if FileManager.default.fileExists(atPath: outputPath) {
                callback(false)
                return
            }

            // Log.i("avcToPcm start")
            JXFileDecoder.shared.avcToPcm(avcPath: inputPath, pcmPath: outputPath) { isFinished, progress in
                if progress == 100, isFinished {
                    callback(true)
                } else if progress == -1 {
                    callback(false)
                    // result(FlutterError(code: "-3", message: "Transcoding failed", details: nil))
                }
            }
        }
    }

    deinit {
        closeAllFiles()
    }
}
