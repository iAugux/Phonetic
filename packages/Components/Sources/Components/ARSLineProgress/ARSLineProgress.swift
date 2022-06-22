//
//  ARSLineProgress.swift
//  ARSLineProgress
//
//  Created by Yaroslav Arsenkin on 24.01.16.
//  Copyright © 2016 Iaroslav Arsenkin. All rights reserved.
//
//  Website: http://arsenkin.com
//

import ASKit
import UIKit

public enum ARSLineProgress {
    public typealias CompletionBlock = () -> Void
    public static var shown: Bool { return ars_currentLoader != nil ? true : false }
    public static var statusShown: Bool { return ars_currentStatus != nil ? true : false }

    // MARK: Show Statuses
    /**
     Will interrupt the current .Infinite loader progress and show success animation instead.
     */
    public static func showSuccess() {
        if !statusShown { ARSStatus.show(.success) }
    }

    /**
     Will interrupt the current .Infinite loader progress and show fail animation instead.
     */
    public static func showFail() {
        if !statusShown { ARSStatus.show(.fail) }
    }

    // MARK: Show Infinite Loader

    public static func show() {
        if !shown { ARSInfiniteLoader().showOnView(nil, completionBlock: nil) }
    }

    public static func showWithPresentCompetionBlock(_ block: CompletionBlock?) {
        if !shown { ARSInfiniteLoader().showOnView(nil, completionBlock: block) }
    }

    public static func showOnView(_ view: UIView) {
        if !shown { ARSInfiniteLoader().showOnView(view, completionBlock: nil) }
    }

    public static func showOnView(_ view: UIView, completionBlock: CompletionBlock?) {
        if !shown { ARSInfiniteLoader().showOnView(view, completionBlock: completionBlock) }
    }

    // MARK: Show Progress Loader

    /**
     - note: initialValue should be from 0 to 100
     */
    public static func showWithProgress(initialValue value: CGFloat) {
        if !shown { ARSProgressLoader().showWithValue(value, onView: nil, progress: nil, completionBlock: nil) }
    }

    /**
     - note: initialValue should be from 0 to 100
     */
    public static func showWithProgress(initialValue value: CGFloat, onView: UIView) {
        if !shown { ARSProgressLoader().showWithValue(value, onView: onView, progress: nil, completionBlock: nil) }
    }

    /**
     - note: initialValue should be from 0 to 100
     */
    public static func showWithProgress(initialValue value: CGFloat, completionBlock: Closure?) {
        if !shown { ARSProgressLoader().showWithValue(value, onView: nil, progress: nil, completionBlock: completionBlock) }
    }

    /**
     - note: initialValue should be from 0 to 100
     */
    public static func showWithProgress(initialValue value: CGFloat, onView: UIView, completionBlock: Closure?) {
        if !shown { ARSProgressLoader().showWithValue(value, onView: onView, progress: nil, completionBlock: completionBlock) }
    }

    public static func showWithProgressObject(_ progress: Progress) {
        if !shown { ARSProgressLoader().showWithValue(0.0, onView: nil, progress: progress, completionBlock: nil) }
    }

    public static func showWithProgressObject(_ progress: Progress, completionBlock: Closure?) {
        if !shown { ARSProgressLoader().showWithValue(0.0, onView: nil, progress: progress, completionBlock: completionBlock) }
    }

    public static func showWithProgressObject(_ progress: Progress, onView: UIView) {
        if !shown { ARSProgressLoader().showWithValue(0.0, onView: onView, progress: progress, completionBlock: nil) }
    }

    public static func showWithProgressObject(_ progress: Progress, onView: UIView, completionBlock: Closure?) {
        if !shown { ARSProgressLoader().showWithValue(0.0, onView: onView, progress: progress, completionBlock: completionBlock) }
    }

    // MARK: Update Progress Loader

    public static func updateWithProgress(_ value: CGFloat) {
        ARSProgressLoader.weakSelf?.progressValue = value
    }

    public static func cancelPorgressWithFailAnimation(_ showFail: Bool) {
        ARSProgressLoader.weakSelf?.cancelWithFailAnimation(showFail, completionBlock: nil)
    }

    public static func cancelPorgressWithFailAnimation(_ showFail: Bool, completionBlock: Closure?) {
        ARSProgressLoader.weakSelf?.cancelWithFailAnimation(showFail, completionBlock: completionBlock)
    }

    // MARK: Hide Loader

    public static func hide() {
        ars_hideLoader(ars_currentLoader, withCompletionBlock: nil)
    }

    public static func hideWithCompletionBlock(_ block: CompletionBlock?) {
        ars_hideLoader(ars_currentLoader, withCompletionBlock: block)
    }
}

public enum ARSLineProgressConfiguration {
    public static var showSuccessCheckmark = true

    public static var backgroundViewCornerRadius: CGFloat = 20.0
    public static var backgroundViewPresentAnimationDuration: CFTimeInterval = 0.3
    public static var backgroundViewDismissAnimationDuration: CFTimeInterval = 0.3

    public static var blurStyle: UIBlurEffect.Style = .dark
    public static var circleColorOuter: CGColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor
    public static var circleColorMiddle: CGColor = UIColor.ars_colorWithRGB(82.0, green: 124.0, blue: 194.0, alpha: 1.0).cgColor
    public static var circleColorInner: CGColor = UIColor.ars_colorWithRGB(60.0, green: 132.0, blue: 196.0, alpha: 1.0).cgColor

    public static var circleRotationDurationOuter: CFTimeInterval = 3.0
    public static var circleRotationDurationMiddle: CFTimeInterval = 1.5
    public static var circleRotationDurationInner: CFTimeInterval = 0.75

    public static var checkmarkAnimationDrawDuration: CFTimeInterval = 0.4
    public static var checkmarkLineWidth: CGFloat = 2.0
    public static var checkmarkColor: CGColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

    public static var successCircleAnimationDrawDuration: CFTimeInterval = 0.7
    public static var successCircleLineWidth: CGFloat = 2.0
    public static var successCircleColor: CGColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

    public static var failCrossAnimationDrawDuration: CFTimeInterval = 0.4
    public static var failCrossLineWidth: CGFloat = 2.0
    public static var failCrossColor: CGColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

    public static var failCircleAnimationDrawDuration: CFTimeInterval = 0.7
    public static var failCircleLineWidth: CGFloat = 2.0
    public static var failCircleColor: CGColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

    /**
     Use this function to restore all properties to their default values.
     */
    public static func restoreDefaults() {
        ars_config.showSuccessCheckmark = true

        ars_config.backgroundViewCornerRadius = 20.0
        ars_config.backgroundViewPresentAnimationDuration = 0.3
        ars_config.backgroundViewDismissAnimationDuration = 0.3

        ars_config.blurStyle = .dark
        ars_config.circleColorOuter = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor
        ars_config.circleColorMiddle = UIColor.ars_colorWithRGB(82.0, green: 124.0, blue: 194.0, alpha: 1.0).cgColor
        ars_config.circleColorInner = UIColor.ars_colorWithRGB(60.0, green: 132.0, blue: 196.0, alpha: 1.0).cgColor

        ars_config.circleRotationDurationOuter = 3.0
        ars_config.circleRotationDurationMiddle = 1.5
        ars_config.circleRotationDurationInner = 0.75

        ars_config.checkmarkAnimationDrawDuration = 0.4
        ars_config.checkmarkLineWidth = 2.0
        ars_config.checkmarkColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

        ars_config.successCircleAnimationDrawDuration = 0.7
        ars_config.successCircleLineWidth = 2.0
        ars_config.successCircleColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

        ars_config.failCrossAnimationDrawDuration = 0.4
        ars_config.failCrossLineWidth = 2.0
        ars_config.failCrossColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor

        ars_config.failCircleAnimationDrawDuration = 0.7
        ars_config.failCircleLineWidth = 2.0
        ars_config.failCircleColor = UIColor.ars_colorWithRGB(130.0, green: 149.0, blue: 173.0, alpha: 1.0).cgColor
    }
}

// =====================================================================================================================
// MARK: - Protocols, Typealiases & Enums
// =====================================================================================================================

private typealias ars_config = ARSLineProgressConfiguration

@objc private protocol ARSLoader {
    var backgroundView: UIVisualEffectView { get set }
    @objc optional var outerCircle: CAShapeLayer { get set }
    @objc optional var middleCircle: CAShapeLayer { get set }
    @objc optional var innerCircle: CAShapeLayer { get set }
    @objc optional weak var targetView: UIView? { get set }
}

private enum ARSLoaderType {
    case infinite
    case progress
}

// =====================================================================================================================
// MARK: - Shared Constants
// =====================================================================================================================

private let ARS_BACKGROUND_VIEW_SIDE_LENGTH: CGFloat = 125.0

private let ARS_CIRCLE_ROTATION_TO_VALUE = 2 * CGFloat.pi
private let ARS_CIRCLE_ROTATION_REPEAT_COUNT = Float(UINT64_MAX)
private let ARS_CIRCLE_RADIUS_OUTER: CGFloat = 40.0
private let ARS_CIRCLE_RADIUS_MIDDLE: CGFloat = 30.0
private let ARS_CIRCLE_RADIUS_INNER: CGFloat = 20.0
private let ARS_CIRCLE_LINE_WIDTH: CGFloat = 2.0
private let ARS_CIRCLE_START_ANGLE: CGFloat = -CGFloat.pi / 2
private let ARS_CIRCLE_END_ANGLE: CGFloat = 0.0

private weak var ars_currentStatus: ARSLoader?
private var ars_currentLoader: ARSLoader?
private var ars_currentCompletionBlock: Closure?

// =====================================================================================================================
// MARK: - Infinite Loader
// =====================================================================================================================

private final class ARSInfiniteLoader: ARSLoader {
    @objc var backgroundView: UIVisualEffectView
    @objc var outerCircle = CAShapeLayer()
    @objc var middleCircle = CAShapeLayer()
    @objc var innerCircle = CAShapeLayer()
    @objc weak var targetView: UIView?

    init() {
        backgroundView = ARSBlurredBackgroundRect().view
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ARSInfiniteLoader.orientationChanged(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
    }

    @objc func orientationChanged(_ notification: Notification) {
        if let loader = ars_currentLoader {
            if let targetView = loader.targetView {
                _ = ars_createdFrameForBackgroundView(loader.backgroundView, onView: targetView)
            } else {
                _ = ars_createdFrameForBackgroundView(loader.backgroundView, onView: nil)
            }
        }
    }
}

private extension ARSInfiniteLoader {
    func showOnView(_ view: UIView?, completionBlock: Closure?) {
        if ars_createdFrameForBackgroundView(backgroundView, onView: view) == false { return }

        targetView = view

        ars_createCircles(outerCircle,
                          middleCircle: middleCircle,
                          innerCircle: innerCircle,
                          onView: backgroundView.contentView,
                          loaderType: .infinite)
        ars_animateCircles(outerCircle, middleCircle: middleCircle, innerCircle: innerCircle)
        ars_presentLoader(self, onView: view, completionBlock: completionBlock)
    }
}

// =====================================================================================================================
// MARK: - Progress Loader
// =====================================================================================================================

private final class ARSProgressLoader: ARSLoader {
    @objc var backgroundView: UIVisualEffectView
    @objc var outerCircle = CAShapeLayer()
    @objc var middleCircle = CAShapeLayer()
    @objc var innerCircle = CAShapeLayer()
    var multiplier: CGFloat = 1.0
    var lastMultiplierValue: CGFloat = 0.0
    var progressValue: CGFloat = 0.0
    var progress: Progress?
    var failed = false
    weak static var weakSelf: ARSProgressLoader?
    @objc weak var targetView: UIView?

    init() {
        backgroundView = ARSBlurredBackgroundRect().view
        ARSProgressLoader.weakSelf = self
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ARSInfiniteLoader.orientationChanged(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
    }

    @objc func orientationChanged(_ notification: Notification) {
        if let loader = ars_currentLoader {
            if let targetView = loader.targetView {
                _ = ars_createdFrameForBackgroundView(loader.backgroundView, onView: targetView)
            } else {
                _ = ars_createdFrameForBackgroundView(loader.backgroundView, onView: nil)
            }
        }
    }
}

private extension ARSProgressLoader {
    // MARK: Show/Cancel

    func showWithValue(_ value: CGFloat, onView view: UIView?, progress: Progress?, completionBlock: Closure?) {
        if ars_createdFrameForBackgroundView(backgroundView, onView: view) == false { return }
        if let progress = progress { self.progress = progress }

        ars_currentCompletionBlock = completionBlock
        targetView = view

        ars_createCircles(outerCircle,
                          middleCircle: middleCircle,
                          innerCircle: innerCircle,
                          onView: backgroundView.contentView,
                          loaderType: .progress)
        ars_animateCircles(outerCircle, middleCircle: middleCircle, innerCircle: innerCircle)
        ars_presentLoader(self, onView: view, completionBlock: nil)
        launchTimer()
    }

    func cancelWithFailAnimation(_ failAnim: Bool, completionBlock: Closure?) {
        if failAnim {
            ars_currentCompletionBlock = completionBlock
            failed = true
        } else {
            ars_hideLoader(ars_currentLoader, withCompletionBlock: completionBlock)
        }
    }

    // MARK: Configs & Animations

    func launchTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            guard let strongSelf = ARSProgressLoader.weakSelf else { return }
            strongSelf.incrementCircleRadius()
            strongSelf.launchTimer()
        }
    }

    func incrementCircleRadius() {
        if didIncrementMultiplier() == false { return }

        drawCirclePath()

        if failed && multiplier <= 0.0 {
            ARSProgressLoader.weakSelf = nil
            multiplier = 0.01
            drawCirclePath()
            failedLoading()
        } else if multiplier >= 100 {
            ARSProgressLoader.weakSelf = nil
            completed()
        }
    }

    func drawCirclePath() {
        let viewBounds = backgroundView.bounds
        let center = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
        let endAngle = .pi / 180 * 3.6 * multiplier
        let outerPath = UIBezierPath(arcCenter: center, radius: ARS_CIRCLE_RADIUS_OUTER, startAngle: 0, endAngle: endAngle, clockwise: true)
        let middlePath = UIBezierPath(arcCenter: center, radius: ARS_CIRCLE_RADIUS_MIDDLE, startAngle: 0, endAngle: endAngle, clockwise: true)
        let innerPath = UIBezierPath(arcCenter: center, radius: ARS_CIRCLE_RADIUS_INNER, startAngle: 0, endAngle: endAngle, clockwise: true)

        self.outerCircle.path = outerPath.cgPath
        self.middleCircle.path = middlePath.cgPath
        self.innerCircle.path = innerPath.cgPath
    }

    func didIncrementMultiplier() -> Bool {
        if failed {
            multiplier -= 1.5
            return true
        }

        let progress: CGFloat = progressSource()
        if lastMultiplierValue == progress { return false }

        if progress / multiplier > 2 {
            if multiplier < progress {
                multiplier += 0.75
            }
        } else {
            if multiplier < progress {
                multiplier += 0.25
            }
        }
        lastMultiplierValue = multiplier

        return true
    }

    func progressSource() -> CGFloat {
        if let progress = self.progress {
            return CGFloat(progress.fractionCompleted * 100.0)
        } else {
            return progressValue
        }
    }

    func completed() {
        let transform = CATransform3DMakeScale(0.01, 0.01, 1)

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.70, -0.80, 0.68, 0.95))
        self.innerCircle.transform = transform
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.7)
        self.middleCircle.transform = transform
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.9)
        self.outerCircle.transform = transform
        CATransaction.commit()
        CATransaction.commit()
        CATransaction.commit()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if ars_config.showSuccessCheckmark {
                ARSStatus.show(.success)
                let dismissDelay = 0.5 + max(ars_config.successCircleAnimationDrawDuration, ars_config.checkmarkAnimationDrawDuration)
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                    ars_hideLoader(ars_currentLoader, withCompletionBlock: ars_currentCompletionBlock)
                }
            } else {
                ars_hideLoader(ars_currentLoader, withCompletionBlock: ars_currentCompletionBlock)
            }
        }
    }

    func failedLoading() {
        ARSStatus.show(.fail)
        let dismissDelay = 0.5 + max(ars_config.failCircleAnimationDrawDuration, ars_config.failCrossAnimationDrawDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            ars_hideLoader(ars_currentLoader, withCompletionBlock: ars_currentCompletionBlock)
        }
    }

    func cleanup() {
        backgroundView.removeFromSuperview()
    }
}

// =====================================================================================================================
// MARK: - Success Status
// =====================================================================================================================

private enum ARSStatusType {
    case success
    case fail
}

private final class ARSStatus: ARSLoader {
    @objc var backgroundView: UIVisualEffectView

    init() {
        backgroundView = ARSBlurredBackgroundRect().view
        _ = ars_createdFrameForBackgroundView(backgroundView, onView: nil)
    }

    static func show(_ type: ARSStatusType) {
        if let loader = ars_currentLoader {
            ars_stopCircleAnimations(loader, completionBlock: {
                drawStatus(type, loader: loader)
            })
        } else {
            let loader = ARSStatus()
            ars_presentLoader(loader, onView: nil, completionBlock: {
                drawStatus(type, loader: loader)
            })
        }
    }

    static func drawStatus(_ type: ARSStatusType, loader: ARSLoader) {
        ars_currentStatus = loader

        switch type {
        case .success:
            ARSStatus.drawSuccess(loader.backgroundView)
        case .fail:
            ARSStatus.drawFail(loader.backgroundView)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            ars_hideLoader(loader, withCompletionBlock: nil)
        }
    }
}

private extension ARSStatus {
    static func drawSuccess(_ backgroundView: UIVisualEffectView) {
        let backgroundViewBounds = backgroundView.bounds
        let backgroundLayer = backgroundView.layer
        let outerCircleHeight = backgroundViewBounds.height
        let outerCircleWidth = backgroundViewBounds.width

        let checkmarkPath = UIBezierPath()
        checkmarkPath.move(to: CGPoint(x: outerCircleWidth * 0.28, y: outerCircleHeight * 0.53))
        checkmarkPath.addLine(to: CGPoint(x: outerCircleWidth * 0.42, y: outerCircleHeight * 0.66))
        checkmarkPath.addLine(to: CGPoint(x: outerCircleWidth * 0.72, y: outerCircleHeight * 0.36))
        checkmarkPath.lineCapStyle = .square

        let checkmark = CAShapeLayer()
        checkmark.path = checkmarkPath.cgPath
        checkmark.fillColor = nil
        checkmark.strokeColor = ars_config.checkmarkColor
        checkmark.lineWidth = ars_config.checkmarkLineWidth
        backgroundLayer.addSublayer(checkmark)

        let successCircleArcCenter = CGPoint(x: backgroundViewBounds.midX, y: backgroundViewBounds.midY)
        let successCircle = CAShapeLayer()
        successCircle.path = UIBezierPath(arcCenter: successCircleArcCenter,
                                          radius: ARS_CIRCLE_RADIUS_OUTER,
                                          startAngle: -CGFloat.pi / 2,
                                          endAngle: CGFloat.pi / 180 * 270,
                                          clockwise: true).cgPath
        successCircle.fillColor = nil
        successCircle.strokeColor = ars_config.successCircleColor
        successCircle.lineWidth = ars_config.successCircleLineWidth
        backgroundLayer.addSublayer(successCircle)

        let animationCheckmark = CABasicAnimation(keyPath: "strokeEnd")
        animationCheckmark.isRemovedOnCompletion = true
        animationCheckmark.fromValue = 0
        animationCheckmark.toValue = 1
        animationCheckmark.fillMode = .both
        animationCheckmark.duration = ars_config.checkmarkAnimationDrawDuration
        animationCheckmark.timingFunction = CAMediaTimingFunction(name: .easeOut)
        checkmark.add(animationCheckmark, forKey: nil)

        let animationCircle = CABasicAnimation(keyPath: "strokeEnd")
        animationCircle.isRemovedOnCompletion = true
        animationCircle.fromValue = 0
        animationCircle.toValue = 1
        animationCircle.fillMode = .both
        animationCircle.duration = ars_config.successCircleAnimationDrawDuration
        animationCircle.timingFunction = CAMediaTimingFunction(name: .easeOut)
        successCircle.add(animationCircle, forKey: nil)
    }

    static func drawFail(_ backgroundView: UIVisualEffectView) {
        let backgroundViewBounds = backgroundView.bounds
        let backgroundViewLayer = backgroundView.layer
        let outerCircleWidth = backgroundViewBounds.width
        let outerCircleHeight = backgroundViewBounds.height

        let crossPath = UIBezierPath()
        crossPath.move(to: CGPoint(x: outerCircleWidth * 0.67, y: outerCircleHeight * 0.32))
        crossPath.addLine(to: CGPoint(x: outerCircleWidth * 0.32, y: outerCircleHeight * 0.67))
        crossPath.move(to: CGPoint(x: outerCircleWidth * 0.32, y: outerCircleHeight * 0.32))
        crossPath.addLine(to: CGPoint(x: outerCircleWidth * 0.67, y: outerCircleHeight * 0.67))
        crossPath.lineCapStyle = .square

        let cross = CAShapeLayer()
        cross.path = crossPath.cgPath
        cross.fillColor = nil
        cross.strokeColor = ars_config.failCrossColor
        cross.lineWidth = ars_config.failCrossLineWidth
        cross.frame = backgroundViewBounds
        backgroundViewLayer.addSublayer(cross)

        let failCircleArcCenter = CGPoint(x: backgroundViewBounds.midX, y: backgroundViewBounds.midY)
        let failCircle = CAShapeLayer()
        failCircle.path = UIBezierPath(arcCenter: failCircleArcCenter,
                                       radius: ARS_CIRCLE_RADIUS_OUTER,
                                       startAngle: -CGFloat.pi / 2,
                                       endAngle: CGFloat.pi / 180 * 270,
                                       clockwise: true).cgPath
        failCircle.fillColor = nil
        failCircle.strokeColor = ars_config.failCircleColor
        failCircle.lineWidth = ars_config.failCircleLineWidth
        backgroundViewLayer.addSublayer(failCircle)

        let animationCross = CABasicAnimation(keyPath: "strokeEnd")
        animationCross.isRemovedOnCompletion = false
        animationCross.fromValue = 0
        animationCross.toValue = 1
        animationCross.duration = ars_config.failCrossAnimationDrawDuration
        animationCross.fillMode = .both
        animationCross.timingFunction = CAMediaTimingFunction(name: .easeIn)
        cross.add(animationCross, forKey: nil)

        let animationCircle = CABasicAnimation(keyPath: "opacity")
        animationCircle.isRemovedOnCompletion = true
        animationCircle.fromValue = 0
        animationCircle.toValue = 1
        animationCircle.fillMode = .both
        animationCircle.duration = ars_config.failCircleAnimationDrawDuration
        animationCircle.timingFunction = CAMediaTimingFunction(name: .easeOut)
        failCircle.add(animationCircle, forKey: nil)
    }
}

// =====================================================================================================================
// MARK: - Background Rect
// =====================================================================================================================

private struct ARSBlurredBackgroundRect {
    var view: UIVisualEffectView

    init() {
        //        let blur = UIBlurEffect(style: ars_config.blurStyle)
        let effectView = UIVisualEffectView(effect: nil)
        effectView.clipsToBounds = true

        view = effectView
        view.backgroundColor = UIColor.clear
    }
}

// =====================================================================================================================
// MARK: - Extensions & Helpers & Shared Methods
// =====================================================================================================================

private func ars_stopCircleAnimations(_ loader: ARSLoader, completionBlock: Closure?) {
    CATransaction.begin()
    CATransaction.setAnimationDuration(0.25)
    CATransaction.setCompletionBlock(completionBlock)
    loader.outerCircle?.opacity = 0.0
    loader.middleCircle?.opacity = 0.0
    loader.innerCircle?.opacity = 0.0
    CATransaction.commit()
}

private func ars_presentLoader(_ loader: ARSLoader, onView view: UIView?, completionBlock: Closure?) {
    ars_currentLoader = loader
    let backgroundView = loader.backgroundView

    DispatchQueue.main.async {
        if let targetView = view {
            targetView.addSubview(backgroundView)
        } else {
            ars_window()!.addSubview(backgroundView)
        }

        backgroundView.alpha = 0.1
        UIView.animate(withDuration: ars_config.backgroundViewPresentAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: {
            backgroundView.alpha = 1.0
        }, completion: { _ in completionBlock?() })
    }
}

private func ars_hideLoader(_ loader: ARSLoader?, withCompletionBlock block: Closure?) {
    guard let loader = loader else { return }

    let backgroundView = loader.backgroundView

    DispatchQueue.main.async {
        UIView.animate(withDuration: ars_config.backgroundViewDismissAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: {
            backgroundView.alpha = 0.0
            backgroundView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: { _ in block?() })
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + ars_config.backgroundViewDismissAnimationDuration) {
        ars_cleanupLoader(loader)
    }
}

private func ars_window() -> UIWindow? {
    var targetWindow: UIWindow?
    let windows = UIApplication.shared.windows
    for window in windows {
        if window.screen != UIScreen.main { continue }
        if !window.isHidden && window.alpha == 0 { continue }
        if window.windowLevel != UIWindow.Level.normal { continue }

        targetWindow = window
        break
    }

    return targetWindow
}

private func ars_createdFrameForBackgroundView(_ backgroundView: UIView, onView view: UIView?) -> Bool {
    let center: CGPoint

    if view == nil {
        guard let window = ars_window() else { return false }
        center = CGPoint(x: window.screen.bounds.midX, y: window.screen.bounds.midY)
    } else {
        let viewBounds = view!.bounds
        center = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
    }

    let sideLengths = ARS_BACKGROUND_VIEW_SIDE_LENGTH
    backgroundView.frame = CGRect(x: center.x - sideLengths / 2, y: center.y - sideLengths / 2, width: sideLengths, height: sideLengths)
    backgroundView.layer.cornerRadius = ars_config.backgroundViewCornerRadius

    return true
}

private func ars_createCircles(_ outerCircle: CAShapeLayer, middleCircle: CAShapeLayer, innerCircle: CAShapeLayer, onView view: UIView, loaderType: ARSLoaderType) {
    let circleRadiusOuter = ARS_CIRCLE_RADIUS_OUTER
    let circleRadiusMiddle = ARS_CIRCLE_RADIUS_MIDDLE
    let circleRadiusInner = ARS_CIRCLE_RADIUS_INNER
    let viewBounds = view.bounds
    let arcCenter = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
    var path: UIBezierPath

    switch loaderType {
    case .infinite:
        path = UIBezierPath(arcCenter: arcCenter,
                            radius: circleRadiusOuter,
                            startAngle: ARS_CIRCLE_START_ANGLE,
                            endAngle: ARS_CIRCLE_END_ANGLE,
                            clockwise: true)
    case .progress:
        path = UIBezierPath(arcCenter: arcCenter,
                            radius: circleRadiusOuter,
                            startAngle: 0,
                            endAngle: CGFloat.pi / 180 * 3.6 * 1,
                            clockwise: true)
    }
    ars_configureLayer(outerCircle, forView: view, withPath: path.cgPath, withBounds: viewBounds, withColor: ars_config.circleColorOuter)

    switch loaderType {
    case .infinite:
        path = UIBezierPath(arcCenter: arcCenter,
                            radius: circleRadiusMiddle,
                            startAngle: ARS_CIRCLE_START_ANGLE,
                            endAngle: ARS_CIRCLE_END_ANGLE,
                            clockwise: true)
    case .progress:
        path = UIBezierPath(arcCenter: arcCenter,
                            radius: circleRadiusMiddle,
                            startAngle: 0,
                            endAngle: CGFloat.pi / 180 * 3.6 * 1,
                            clockwise: true)
    }
    ars_configureLayer(middleCircle, forView: view, withPath: path.cgPath, withBounds: viewBounds, withColor: ars_config.circleColorMiddle)

    switch loaderType {
    case .infinite:
        path = UIBezierPath(arcCenter: arcCenter,
                            radius: circleRadiusInner,
                            startAngle: ARS_CIRCLE_START_ANGLE,
                            endAngle: ARS_CIRCLE_END_ANGLE,
                            clockwise: true)
    case .progress:
        path = UIBezierPath(arcCenter: arcCenter,
                            radius: circleRadiusInner,
                            startAngle: 0,
                            endAngle: CGFloat.pi / 180 * 3.6 * 1,
                            clockwise: true)
    }
    ars_configureLayer(innerCircle, forView: view, withPath: path.cgPath, withBounds: viewBounds, withColor: ars_config.circleColorInner)
}

private func ars_configureLayer(_ layer: CAShapeLayer, forView view: UIView, withPath path: CGPath, withBounds bounds: CGRect, withColor color: CGColor) {
    layer.path = path
    layer.frame = bounds
    layer.lineWidth = ARS_CIRCLE_LINE_WIDTH
    layer.strokeColor = color
    layer.fillColor = UIColor.clear.cgColor
    view.layer.addSublayer(layer)
}

private func ars_animateCircles(_ outerCircle: CAShapeLayer, middleCircle: CAShapeLayer, innerCircle: CAShapeLayer) {
    DispatchQueue.main.async {
        let outerAnimation = CABasicAnimation(keyPath: "transform.rotation")
        outerAnimation.toValue = ARS_CIRCLE_ROTATION_TO_VALUE
        outerAnimation.duration = ars_config.circleRotationDurationOuter
        outerAnimation.repeatCount = ARS_CIRCLE_ROTATION_REPEAT_COUNT
        outerCircle.add(outerAnimation, forKey: "outerCircleRotation")

        let middleAnimation = outerAnimation.copy() as! CABasicAnimation
        middleAnimation.duration = ars_config.circleRotationDurationMiddle
        middleCircle.add(middleAnimation, forKey: "middleCircleRotation")

        let innerAnimation = middleAnimation.copy() as! CABasicAnimation
        innerAnimation.duration = ars_config.circleRotationDurationInner
        innerCircle.add(innerAnimation, forKey: "middleCircleRotation")
    }
}

private func ars_cleanupLoader(_ loader: ARSLoader) {
    loader.backgroundView.removeFromSuperview()
    ars_currentLoader = nil
    ars_currentCompletionBlock = nil
}

private extension UIColor {
    static func ars_colorWithRGB(_ red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}
