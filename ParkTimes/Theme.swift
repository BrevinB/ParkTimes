//
//  Theme.swift
//  ParkTimes
//

import SwiftUI
import UIKit

extension Color {
    private static func adaptive(dark: UIColor, light: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// App background — midnight sky in dark mode, airy off-white in light.
    static let midnight = adaptive(
        dark: UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1),
        light: UIColor(red: 0.955, green: 0.96, blue: 0.985, alpha: 1)
    )
    static let deepNavy = adaptive(
        dark: UIColor(red: 0.08, green: 0.09, blue: 0.18, alpha: 1),
        light: UIColor(red: 0.92, green: 0.93, blue: 0.97, alpha: 1)
    )
    static let cardBackground = adaptive(
        dark: UIColor(red: 0.11, green: 0.12, blue: 0.22, alpha: 1),
        light: UIColor.white
    )
    static let surface = adaptive(
        dark: UIColor(red: 0.15, green: 0.16, blue: 0.28, alpha: 1),
        light: UIColor(red: 0.925, green: 0.935, blue: 0.965, alpha: 1)
    )

    /// Shared thresholds for wait-time coloring across cards, map and detail.
    static func forWait(_ minutes: Int) -> Color {
        if minutes < 30 { return .green }
        if minutes < 60 { return .orange }
        return .red
    }
}

// MARK: - Park Styling

struct ParkStyle {
    let colors: [Color]
    let icon: String

    static let fallback = ParkStyle(colors: [.blue, .purple], icon: "star.fill")

    static let byParkId: [String: ParkStyle] = [
        // Magic Kingdom
        "75ea578a-adc8-4116-a54d-dccb60765ef9": ParkStyle(
            colors: [Color(red: 0.16, green: 0.11, blue: 0.56), Color(red: 0.40, green: 0.25, blue: 0.85)],
            icon: "sparkles"
        ),
        // EPCOT
        "47f90d2c-e191-4239-a466-5892ef59a88b": ParkStyle(
            colors: [Color(red: 0.05, green: 0.36, blue: 0.48), Color(red: 0.10, green: 0.62, blue: 0.72)],
            icon: "globe.americas.fill"
        ),
        // Hollywood Studios
        "288747d1-8b4f-4a64-867e-ea7c9b27bad8": ParkStyle(
            colors: [Color(red: 0.58, green: 0.08, blue: 0.12), Color(red: 0.85, green: 0.32, blue: 0.15)],
            icon: "theatermasks.fill"
        ),
        // Animal Kingdom
        "1c84a229-8862-4648-9c71-378ddd2c7693": ParkStyle(
            colors: [Color(red: 0.08, green: 0.38, blue: 0.20), Color(red: 0.22, green: 0.62, blue: 0.35)],
            icon: "leaf.fill"
        ),
        // Islands of Adventure
        "267615cc-8943-4c2a-ae2c-5da728ca591f": ParkStyle(
            colors: [Color(red: 0.08, green: 0.18, blue: 0.48), Color(red: 0.15, green: 0.40, blue: 0.65)],
            icon: "map.fill"
        ),
        // Universal Studios
        "eb3f4560-2383-4a36-9152-6b3e5ed6bc57": ParkStyle(
            colors: [Color(red: 0.72, green: 0.28, blue: 0.02), Color(red: 0.92, green: 0.55, blue: 0.12)],
            icon: "film.fill"
        ),
        // Epic Universe
        "12dbb85b-265f-44e6-bccf-f1faa17211fc": ParkStyle(
            colors: [Color(red: 0.32, green: 0.08, blue: 0.55), Color(red: 0.68, green: 0.22, blue: 0.55)],
            icon: "star.fill"
        ),
    ]
}

extension ParkModel {
    var style: ParkStyle {
        ParkStyle.byParkId[id] ?? .fallback
    }
}

// MARK: - Night Sky

/// The app's signature: a quietly twinkling starfield with an occasional
/// shooting star. Deterministic per star index so it never flickers on
/// re-render, and completely static when Reduce Motion is on.
struct StarfieldView: View {
    var starCount: Int = 70

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Canvas { context, size in
                draw(context, size: size, time: 0, animated: false)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                Canvas { context, size in
                    draw(context, size: size, time: timeline.date.timeIntervalSinceReferenceDate, animated: true)
                }
            }
        }
    }

    /// Cheap deterministic pseudo-random in [0, 1).
    private func rnd(_ seed: Double) -> Double {
        let value = sin(seed) * 43758.5453
        return value - floor(value)
    }

    private func draw(_ context: GraphicsContext, size: CGSize, time: Double, animated: Bool) {
        for index in 0..<starCount {
            let seed = Double(index)
            let x = rnd(seed * 12.9898) * size.width
            let y = rnd(seed * 78.233) * size.height
            let radius = 0.6 + rnd(seed * 3.7) * 1.4
            let phase = rnd(seed * 9.1) * 2 * .pi
            let speed = 0.4 + rnd(seed * 5.3) * 0.8

            let alpha = animated
                ? 0.18 + 0.45 * (0.5 + 0.5 * sin(time * speed + phase))
                : 0.35

            let rect = CGRect(x: x, y: y, width: radius, height: radius)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
        }

        guard animated else { return }

        // A shooting star roughly every nine seconds, in the top half of the sky.
        let period = 9.0
        let flight = 0.9
        let t = time.truncatingRemainder(dividingBy: period)
        if t < flight {
            let cycle = floor(time / period)
            let progress = t / flight
            let fade = sin(progress * .pi)

            let startX = rnd(cycle * 3.31) * size.width * 0.7
            let startY = rnd(cycle * 7.73) * size.height * 0.35
            let head = CGPoint(x: startX + 110 * progress, y: startY + 50 * progress)
            let tail = CGPoint(x: head.x - 30, y: head.y - 14)

            var path = Path()
            path.move(to: tail)
            path.addLine(to: head)
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [.white.opacity(0), .white.opacity(0.65 * fade)]),
                    startPoint: tail,
                    endPoint: head
                ),
                lineWidth: 1.2
            )
        }
    }
}

struct MagicBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                Color.midnight
                // The night sky belongs to the night — light mode stays clean.
                if colorScheme == .dark {
                    StarfieldView()
                }
            }
            .ignoresSafeArea()
        }
    }
}

extension View {
    /// Midnight background with the ambient starfield behind the content.
    func magicBackground() -> some View {
        modifier(MagicBackground())
    }
}

// MARK: - Press Feedback

/// Springy scale-down while a card is pressed — makes the big park cards
/// feel tactile without adding any ambient motion.
struct MagicCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Voice

/// Themed copy in one place so the app speaks with a single voice.
enum MagicCopy {
    static func greetingSubline(hour: Int) -> String {
        switch hour {
        case 0..<10: return "Rope drop is calling"
        case 10..<17: return "Peak magic hours"
        default: return "Fireworks weather"
        }
    }

    private static let loadingPhrases = [
        "Summoning wait times…",
        "Consulting the crystal ball…",
        "Counting pixie dust…",
        "Asking the castle…",
    ]

    /// Stable for a given seed so the phrase doesn't change mid-load.
    static func loadingPhrase(seed: Int) -> String {
        loadingPhrases[abs(seed) % loadingPhrases.count]
    }

    static let refreshFailed = "The magic didn't reach us — showing older times"
}
