//
//  CaptureFolderManager.swift
//  3DModel
//
//  Created by BS00880 on 20/8/24.
//

import Foundation
import Dispatch
import os

class CaptureFolderManager: ObservableObject {
    static let logger = Logger(subsystem: _DModelApp.subsystem, category: "CaptureFolderManager")
    private let logger = CaptureFolderManager.logger
    
    let rootScanFolder: URL
    let imagesFolder: URL
    let snapshotsFolder: URL
    let outputFolder: URL
    
    private static let imageStringPrefix = "IMG_"
    private static let heicImageExtension = "HEIC"
    
    @Published var shots: [ShotFileInfo] = []
    
    init?() {
        guard let newFolder = CaptureFolderManager.createNewScanDirectory() else {
            logger.error("Unable to create a new scan directory")
            return nil
        }
        rootScanFolder = newFolder
        
        imagesFolder = newFolder.appendingPathComponent("Images/")
        guard CaptureFolderManager.createDirectoryRecursively(imagesFolder) else {
            return nil
        }
        snapshotsFolder = newFolder.appendingPathComponent("Snapshots/")
        guard CaptureFolderManager.createDirectoryRecursively(snapshotsFolder) else {
            return nil
        }
        outputFolder = newFolder.appendingPathComponent("Models/")
        guard CaptureFolderManager.createDirectoryRecursively(outputFolder) else {
            return nil
        }
    }
    
    static func parseShotId(url: URL) -> UInt32? {
        let photoBasename = url.deletingPathExtension().lastPathComponent
        logger.debug("photoBasename = \(photoBasename)")

        guard let endOfPrefix = photoBasename.lastIndex(of: "_") else {
            logger.warning("Can't get endOfPrefix!")
            return nil
        }

        let imgPrefix = photoBasename[...endOfPrefix]
        guard imgPrefix == imageStringPrefix else {
            logger.warning("Prefix doesn't match!")
            return nil
        }

        let idString = photoBasename[photoBasename.index(after: endOfPrefix)...]
        guard let id = UInt32(idString) else {
            logger.warning("Can't convert idString=\"\(idString)\" to uint32!")
            return nil
        }

        return id
    }

    static func createNewScanDirectory() -> URL? {
        guard let capturesFolder = rootScansFolder() else {
            logger.error("Can't get user document dir!")
            return nil
        }

        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = capturesFolder
            .appendingPathComponent(timestamp, isDirectory: true)

        logger.log("Creating capture path: \"\(String(describing: newCaptureDir))\"")
        let capturePath = newCaptureDir.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create capturepath=\"\(capturePath)\" error=\(String(describing: error))")
            return nil
        }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }

        return newCaptureDir
    }
    
    private static func rootScansFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("Scans/", isDirectory: true)
    }
    
    private static func createDirectoryRecursively(_ outputDir: URL) -> Bool {
        guard outputDir.isFileURL else {
            return false
        }
        let expandedPath = outputDir.path
        var isDirectory: ObjCBool = false
        let fileManager = FileManager()
        guard !fileManager.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) else {
            logger.error("File already exists at \(expandedPath, privacy: .private)")
            return false
        }

        logger.log("Creating dir recursively: \"\(expandedPath, privacy: .private)\"")

        let result: ()? = try? fileManager.createDirectory(atPath: expandedPath,
                                                           withIntermediateDirectories: true)

        guard result != nil else {
            return false
        }

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: expandedPath, isDirectory: &isDir) && isDir.boolValue else {
            logger.error("Dir \"\(expandedPath, privacy: .private)\" doesn't exist after creation!")
            return false
        }

        logger.log("... success creating dir.")
        return true
    }
}
