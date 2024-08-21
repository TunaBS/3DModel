//
//  ContentView.swift
//  3DModel
//
//  Created by BS00880 on 19/8/24.
//

import SwiftUI
import RealityKit
import ARKit
import AVFoundation

struct ContentView: View {
    
    @StateObject var appModel: ModelFile = ModelFile.instance
    
    @State private var showReconstructionView: Bool = false
    @State private var showErrorAlert: Bool = false
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }
    
    var body: some View {
        VStack {
//            Text("Hello world")
            if appModel.state == .capturing {
                Text("Entered into capturing state")
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            } else if showProgressView {
                Text("Entered into Circular Progress View")
//                CircularProgressView()
            }
            else {
                Text("Hello world")
            }
        }
        .onChange(of: appModel.state) { _, newState in
            if newState == .failed {
                showErrorAlert = true
                showReconstructionView = false
            } else {
                showErrorAlert = false
                showReconstructionView = newState == .reconstructing || newState == .viewing
            }
        }
        .background(.blue)
//        .sheet(isPresented: $showReconstructionView) {
//            if let folderManager == appModel.scanFolderManager {
//
//            }
//        }
//        .alert(
//            "Failed:  " + (appModel.error != nil  ? "\(String(describing: appModel.error!))" : ""),
//            isPresented: $showErrorAlert,
//            actions: {
//                Button("OK") {
//                    ContentView.logger.log("Calling restart...")
//                    appModel.state = .restart
//                }
//            },
//            message: {}
//        )
        .environmentObject(appModel)
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
