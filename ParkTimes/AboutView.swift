//
//  AboutView.swift
//  ParkTimes
//

import SwiftUI

struct AboutView: View {
    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow.opacity(0.85))
                    Text("ParkTimes")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("Version \(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                card(title: "What this is", icon: "clock.fill", color: .cyan) {
                    Text("Live wait times, park hours, showtimes, and forecasts for theme parks around the world — with favorites, wait alerts, widgets, and Live Activities.")
                }

                card(title: "Where the data comes from", icon: "antenna.radiowaves.left.and.right", color: .green) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wait times are provided by the community-run themeparks.wiki API. Times are estimates and can differ from what's posted in the park.")
                        Link("themeparks.wiki", destination: URL(string: "https://themeparks.wiki")!)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Restroom locations © OpenStreetMap contributors, available under the Open Database License.")
                        Link("openstreetmap.org", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                card(title: "Legal", icon: "checkmark.shield.fill", color: .purple) {
                    Text("ParkTimes is an independent app. It is not affiliated with, endorsed by, or sponsored by The Walt Disney Company, Universal Destinations & Experiences, or any park operator. All park and attraction names are trademarks of their respective owners and are used only to identify the parks they refer to.")
                }

                VStack(spacing: 10) {
                    Link(destination: URL(string: "https://brevinb.github.io/ParkTimes/privacy.html")!) {
                        linkRow(title: "Privacy Policy", icon: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://brevinb.github.io/ParkTimes/")!) {
                        linkRow(title: "Support", icon: "questionmark.circle.fill")
                    }
                }

                Text("Made with a little pixie dust ✨")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .magicBackground()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card(title: String, icon: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    private func linkRow(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.cyan)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
}
