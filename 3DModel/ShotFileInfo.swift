//
//  ShotFileInfo.swift
//  3DModel
//
//  Created by BS00880 on 20/8/24.
//

import Foundation
import Combine
import SwiftUI
import UIKit

struct ShotFileInfo {
    let fileURL: URL
    let id: UInt32

    init?(url: URL) {
        fileURL = url
        guard let shotID = CaptureFolderManager.parseShotId(url: url) else {
            return nil
        }

        id = shotID
    }
}

extension ShotFileInfo: Identifiable { }
