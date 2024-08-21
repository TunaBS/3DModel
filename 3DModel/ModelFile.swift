//
//  ModelFile.swift
//  3DModel
//
//  Created by BS00880 on 20/8/24.
//

import Foundation
import RealityKit
import SwiftUI
import os

@MainActor
class ModelFile: ObservableObject {
    let logger = Logger(subsystem: _DModelApp.subsystem, category: "ModelFile")
    static let instance = ModelFile()
    private var scanFolderManager: CaptureFolderManager!
//    @Published private(set) var showPreviewModel = false
    private(set) var photogrammetrySession: PhotogrammetrySession?
    @Published var state: ModelState = .notSet {
        didSet {
            if state != oldValue {
                performStateTransition(from: oldValue, to: state)
                print("State changed")
            }
        }
    }
    
    @Published var objectCaptureSession: ObjectCaptureSession? {
        willSet {
            detachListeners()
        }
        didSet {
            guard objectCaptureSession != nil else { return }
            attachListeners()
        }
    }
    
    private init(objectCaptureSession: ObjectCaptureSession) {
        self.objectCaptureSession = objectCaptureSession
        state = .ready
    }
    
    private init() {
        state = .ready
    }
    
    deinit {
        DispatchQueue.main.async {
            self.detachListeners()
        }
    }
    
    func endCapture() {
        state = .completed
    }
    private func onStateChanged(newState: ObjectCaptureSession.CaptureState) {
        if case .completed = newState {
            state = .prepareToReconstruct
        } else if case let .failed(error) = newState {
            if case ObjectCaptureSession.Error.cancelled = error {
                state = .restart
            } else {
//                switchToErrorState(error: error)
                print("Need to switch to error state")
            }
        }
    }
    
    private var tasks: [ Task<Void, Never> ] = []

    @MainActor
    private func attachListeners() {
        logger.debug("Attaching listeners...")
        guard let model = objectCaptureSession else {
            fatalError("Logic error")
        }
        
        tasks.append(Task<Void, Never> { [weak self] in
                for await newFeedback in model.feedbackUpdates {
                    self?.logger.debug("Task got async feedback change to: \(String(describing: newFeedback))")
//                    self?.updateFeedbackMessages(for: newFeedback)
                }
        })
        tasks.append(Task<Void, Never> { [weak self] in
            for await newState in model.stateUpdates {
                self?.onStateChanged(newState: newState)
                }
        })
    }

    private func detachListeners() {
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }
    
    
    
    private func startNewCapture() -> Bool {
        if !ObjectCaptureSession.isSupported {
            preconditionFailure("Sorry not supported!")
        }
        
        guard let folderManager = CaptureFolderManager() else {
            return false
        }
        
        scanFolderManager = folderManager
        objectCaptureSession = ObjectCaptureSession()
        
        guard let session = objectCaptureSession else {
            preconditionFailure("startNewCapture has stopped unexpectedly")
        }
        
        var configuration = ObjectCaptureSession.Configuration()
        configuration.checkpointDirectory = scanFolderManager.snapshotsFolder
        configuration.isOverCaptureEnabled = true
        logger.log("Enabling overcapture")
        
        session.start(imagesDirectory: scanFolderManager.imagesFolder, configuration: configuration)
        
        if case let .failed(error) = session.state {
            logger.error("Got error starting session! \(String(describing: error))")
            
        } else {
            state = .capturing
        }
        return true
    }
    
//    func setPreviewModelState(shown: Bool) {
//        guard shown != showPreviewModel else { return }
//        if shown {
//            showPreviewModel = true
//            objectCaptureSession?.pause()
//        } else {
//            objectCaptureSession?.resume()
//            showPreviewModel = false
//        }
//    }
    
    private func performStateTransition(from fromState: ModelState, to toState: ModelState) {
        if fromState == .failed {
//            error = nil
        }

        switch toState {
            case .ready:
                guard startNewCapture() else {
                    logger.error("Starting new capture failed!")
                    break
                }
            case .capturing:
//                orbitState = .initial
                print("capturing")
            case .prepareToReconstruct:
                // Cleans up the session to free GPU and memory resources.
                objectCaptureSession = nil
                do {
//                    try startReconstruction()
                    print("start reconstruction")
                } catch {
                    logger.error("Reconstructing failed!")
                }
            case .restart, .completed:
//                reset()
                print("reset")
            case .viewing:
                photogrammetrySession = nil

                // Removes snapshots folder to free up space after generating the model.
                let snapshotsFolder = scanFolderManager.snapshotsFolder
                DispatchQueue.global(qos: .background).async {
                    try? FileManager.default.removeItem(at: snapshotsFolder)
                }

            case .failed:
                print("Last failed error")
//                logger.error("App failed state error=\(String(describing: self.error!))")
                // Shows error screen.
            default:
                break
        }
    }

}
