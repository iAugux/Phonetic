// Created by Augus on 2021/10/1
// Copyright © 2021 Augus <iAugux@gmail.com>

import UIKit

// Reference: - https://github.com/Yalantis/StarWars.iOS
final class StarsOverlay: UIView {
    private var emitterTimer: Timer?

    override class var layerClass: AnyClass {
        return CAEmitterLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.emitterPosition = center
        emitter.emitterSize = bounds.size
    }

    private var emitter: CAEmitterLayer {
        return layer as! CAEmitterLayer
    }

    private lazy var particle: CAEmitterCell = {
        let particle = CAEmitterCell()
        particle.contents = #imageLiteral(resourceName: "spark").cgImage
        particle.birthRate = 10
        particle.lifetime = 50
        particle.lifetimeRange = 5
        particle.velocity = 20
        particle.velocityRange = 10
        particle.scale = 0.02
        particle.scaleRange = 0.1
        particle.scaleSpeed = 0.02
        return particle
    }()
}

extension StarsOverlay {
    func startAnimating() {
        emitterTimer?.invalidate()
        emitterTimer = Timer.scheduledTimer(timeInterval: 0.08, target: self, selector: #selector(randomizeEmitterPosition), userInfo: nil, repeats: true)
    }

    func stopAnimating() {
        emitterTimer?.invalidate()
        emitterTimer = nil
    }

    private func setUp() {
        emitter.emitterMode = .outline
        emitter.emitterShape = .circle
        emitter.renderMode = .oldestFirst
        emitter.preservesDepth = true
        emitter.emitterCells = [particle]
    }

    @objc
    private func randomizeEmitterPosition() {
        let sizeWidth = max(bounds.width, bounds.height)
        let radius = CGFloat(arc4random()).truncatingRemainder(dividingBy: sizeWidth)
        emitter.emitterSize = CGSize(width: radius, height: radius)
        particle.birthRate = 10 + sqrt(Float(radius))
    }
}
