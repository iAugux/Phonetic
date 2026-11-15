// Created by Augus on 9/28/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

struct CircularProgressView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var diameter: CGFloat = 140

    var percentage: Double

    private let gradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 0.986, green: 0.030, blue: 0.389),
            Color(red: 0.317, green: 0.0, blue: 0.980),
            Color(red: 0.129, green: 0.994, blue: 0.550),
            Color(red: 0.986, green: 0.030, blue: 0.389),
        ]),
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    Color(white: 0.667).opacity(0.3),
                    lineWidth: 6
                )

            // Progress Bar
            Circle()
                .trim(from: 0, to: max(0, min(CGFloat(percentage / 100.0), 1.0)))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.15), value: percentage)

            // Center Percentage
            Text(verbatim: "\(Int(percentage))%")
                .font(.title3.monospaced().weight(.semibold))
        }
        .frame(width: min(diameter, 240), height: min(diameter, 240))
        .accessibilityRepresentation {
            ProgressView(value: max(0, min(percentage, 100)), total: 100) {
                Text("Processing Progress")
            }
        }
    }
}
