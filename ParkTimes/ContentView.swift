//
//  ContentView.swift
//  ParkTimes
//
//  Created by Brevin Blalock on 8/28/23.
//

import SwiftUI

struct ContentView: View {

    private let disneyParks: [ParkModel] = [
        ParkModel(id: "75ea578a-adc8-4116-a54d-dccb60765ef9", name: "Magic Kingdom"),
        ParkModel(id: "47f90d2c-e191-4239-a466-5892ef59a88b", name: "EPCOT"),
        ParkModel(id: "288747d1-8b4f-4a64-867e-ea7c9b27bad8", name: "Hollywood Studios"),
        ParkModel(id: "1c84a229-8862-4648-9c71-378ddd2c7693", name: "Animal Kingdom"),
    ]

    private let universalParks: [ParkModel] = [
        ParkModel(id: "267615cc-8943-4c2a-ae2c-5da728ca591f", name: "Islands of Adventure"),
        ParkModel(id: "eb3f4560-2383-4a36-9152-6b3e5ed6bc57", name: "Universal Studios"),
        ParkModel(id: "12dbb85b-265f-44e6-bccf-f1faa17211fc", name: "Epic Universe"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ParkSection(title: "Walt Disney World", parks: disneyParks)
                    ParkSection(title: "Universal Orlando", parks: universalParks)
                }
                .padding()
            }
            .navigationTitle("Park Times")
        }
    }
}

struct ParkSection: View {
    let title: String
    let parks: [ParkModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ForEach(parks) { park in
                NavigationLink {
                    RidesView(parkId: park.id, parkName: park.name)
                } label: {
                    ParkCardView(park: park)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
