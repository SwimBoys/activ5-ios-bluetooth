//
//  DoubleSqeezeHelper.swift
//  Activ5Device
//
//  Created by Martin Kuvandzhiev on 22.11.19.
//

import Foundation

public struct SqueezeThreshold{
    var pressed = 20.0
    var depressed = 5.0
    
    static let base = SqueezeThreshold(pressed: 20, depressed: 5)
}

public final class DoubleSqeezeHelper {
    typealias VoidClosure = () -> Void

    enum DoublePressState {
        case initial, firstPressed, firstPressCompleted, secondPressed
    }
    static var squeezeThreshold = SqueezeThreshold.base

    static var doublePressState: DoublePressState = .initial
    static var resetTimer: Timer?

    static func evaluateDoublePress(force: Double, onPressed: VoidClosure? = nil, onDepressed: VoidClosure? = nil, onSuccess: VoidClosure) {
        if force > squeezeThreshold.pressed {
            onPressed?()
            switch doublePressState {
            case .initial:
                doublePressState = .firstPressed
            case .firstPressCompleted:
                doublePressState = .secondPressed
            default:
                break
            }
            resetTimer?.invalidate()
            resetTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { (_) in
                doublePressState = .initial
            })
        } else if force < squeezeThreshold.depressed, (doublePressState == .firstPressed || doublePressState == .secondPressed) {
            onDepressed?()
            switch doublePressState {
            case .firstPressed:
                doublePressState = .firstPressCompleted
            case .secondPressed:
                doublePressState = .initial
                resetTimer?.invalidate()
                resetTimer = nil
                onSuccess()
            default:
                break
            }
        }
    }
}
