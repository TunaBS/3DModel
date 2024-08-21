//
//  ModelFile+State.swift
//  3DModel
//
//  Created by BS00880 on 20/8/24.
//

import Foundation

extension ModelFile {
    enum ModelState: String {
        var description: String { rawValue }
        
        case notSet
        case ready
        case capturing
        case prepareToReconstruct
        case reconstructing
        case viewing
        case completed
        case restart
        case failed
    }
}
