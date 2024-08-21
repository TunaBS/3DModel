//
//  CaptureOverlayView.swift
//  3DModel
//
//  Created by BS00880 on 21/8/24.
//

import Foundation
import RealityKit
import SwiftUI

struct CaptureOverlayView: View {
    @EnvironmentObject var appModel: ModelFile
    var session: ObjectCaptureSession
    @State private var hasDetectionFailed = false
    
    private var capturingStarted: Bool {
        switch session.state {
            case .initializing, .ready, .detecting:
                return false
            default:
                return true
        }
    }
    var body: some View {
        VStack {
            if !capturingStarted {
                //add capture button here
                CaptureButton(session: session, hasDetectionFailed: $hasDetectionFailed)
            }
        }
    }
}

extension CaptureOverlayView {
    @MainActor
    struct CaptureButton: View {
        var session: ObjectCaptureSession
        @Binding var hasDetectionFailed: Bool
        var body: some View {
            Button(action: {
                performAction()
            }, label: {
                Text(buttonLabel)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                    .background(.blue)
                    .clipShape(Capsule())
            })
        }
        
        private var buttonLabel: String {
            if case .ready = session.state {
                return NSLocalizedString("Continue", comment: "ready")
            } else {
                return NSLocalizedString("Start Capture", comment: "start capturing")
            }
        }
        
        private func performAction() {
            if case .ready = session.state {
                hasDetectionFailed = !(session.startDetecting())
            } else if case .detecting = session.state {
                session.startCapturing()
            }
        }
    }
}
