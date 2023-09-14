//
//  ContentView.swift
//  ParkTimes
//
//  Created by Brevin Blalock on 8/28/23.
//

import SwiftUI

let dateFormatter = DateFormatter()

struct ContentView: View {
    
    @State private var parks: [ParkModel] = []
    //@State private var rides: [RideModel] = []
    @State private var lands: [LandModel] = []
    //@State private var rides2: Rides?
    @State private var results: LandsAndRides?
    @State private var showRides = false
    @State private var loading = false
    
    let testParkModel: ParkModel = ParkModel(id: 0, name: "Disney")
    
    
    let testLandModel: [LandModel] = [LandModel(id: 0, name: "Test", rides: [RideModel(id: 0, name: "testRide", isOpen: true, waitTime: 0, lastUpdated: "0000")])]
    
    let testRideModel: [RideModel] = [RideModel(id: 0, name: "Test", isOpen: true, waitTime: 0, lastUpdated: "0000")]
    
    var body: some View {
        let testResult: LandsAndRides = LandsAndRides(lands: self.testLandModel, rides: self.testRideModel)
        NavigationStack {
            ZStack {
                if loading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                } else {
                    VStack {
                        ForEach(parks, id: \.id) { park in
                            NavigationLink {
                                RidesView(parkId: park.id)
                            } label: {
                                ParkCard(park: park)
                            }
                        }
                        
                    }
                    .padding()
                }
            }
            .task {
                if parks.isEmpty {
                    loading.toggle()
                    
                    
                    
                    let parksIds = [5, 6, 7, 8, 64, 65]
                    do {
                        for id in parksIds {
                            let park = try await getPark(parkId: id)
                            parks.append(park)
                        }
                        
                        loading.toggle()
                        
                    } catch PTError.invalidUrl {
                        print("Invalid URL")
                    } catch PTError.invalidResponse {
                        print("Invalid Response")
                    } catch PTError.invalidData {
                        print("Invalid Data")
                    } catch {
                        print("Unexpected Error")
                    }
                }
            }
        }
        //        .task {
        //            do {
        //                results = try await getRides(parkId: 6)
        //            } catch PTError.invalidUrl {
        //                print("Invalid URL")
        //            } catch PTError.invalidResponse {
        //                print("Invalid Response")
        //            } catch PTError.invalidData {
        //                print("Invalid Data")
        //            } catch {
        //                print("Unexpected Error")
        //            }
        //        }
    }
    
    func getPark(parkId: Int) async throws -> ParkModel {
        let endpoint = "https://queue-times.com/en-US/parks/\(parkId).json"
        
        guard let url = URL(string: endpoint) else {
            throw PTError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PTError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(ParkModel.self, from: data)
        } catch {
            throw PTError.invalidData
        }
    }
    
    func getRides(parkId: Int) async throws -> LandsAndRides {
        let endpoint = "https://queue-times.com/en-US/parks/\(parkId)queue_times.json"
        
        guard let url = URL(string: endpoint) else {
            throw PTError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PTError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            //decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(LandsAndRides.self, from: data)
        } catch {
            throw PTError.invalidData
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ParkModel: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct LandModel: Codable, Identifiable {
    let id: Int?
    let name: String?
    let rides: [RideModel]?
}

struct RideModel: Codable, Identifiable {
    let id: Int?
    let name: String?
    let isOpen: Bool?
    let waitTime: Int?
    let lastUpdated: String?
}

struct LandsAndRides: Codable {
    let lands: [LandModel]
    let rides: [RideModel]
}

struct ParkCard: View {
    let park: ParkModel
    @State private var iconImage: String = "MagicKingdomImg"
    var body: some View {
        HStack {
            Image("\(iconImage)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
            //                .frame(width: 80, height: 80)
            Text(park.name)
                .bold()
                .font(.title2)
                .foregroundColor(.primary)
        }
        .frame(width: 340, height: 75)
        .background(Color.gray.opacity(0.5))
        .cornerRadius(20)
        .onAppear {
            switch park.id {
            case 5:
                iconImage = "EpcotImg"
                break;
            case 6:
                iconImage = "MagicKingdomImg"
                break;
            case 7:
                iconImage = "HollywoodStudiosImg"
                break;
            case 8:
                iconImage = "AnimalKingdomImg"
                break;
            case 64:
                iconImage = "IslandOfAdventureImg"
                break;
            case 65:
                iconImage = "UniversalStudiosImg"
                break;
            default:
                iconImage = "MagicKingdomImg"
                break;
            }
        }
        
    }
}

struct RidesView: View {
    @State private var results: LandsAndRides?
    @State private var loading = false
    @State private var collapsed = false
    var parkId: Int = 6
    var body: some View {
        let testRideModel: [RideModel] = [RideModel(id: 0, name: "Test Ride", isOpen: true, waitTime: 0, lastUpdated: "0000")]
        let testLandModel: [LandModel] = [LandModel(id: 0, name: "Test Land", rides: testRideModel)]
        let testResultModel: LandsAndRides = LandsAndRides(lands: testLandModel, rides: testRideModel)
        ScrollView {
            ZStack {
                if loading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                } else {
                    VStack {
                        ForEach(results?.lands ?? testResultModel.lands) { land in
                            TestCard(land: land)
//                            VStack(alignment: .leading) {
//                                HStack {
//                                    Text(land.name ?? "Test Land")
//                                        .font(.title2)
//                                        .bold()
//                                    .foregroundColor(.blue)
//
//                                    Button(action: {
//                                        withAnimation(.easeInOut) {
//                                            collapsed.toggle()
//                                        }
//                                    }, label: {
//                                        Text("⌄")
//                                            .font(.title)
//                                    })
//
//                                }
//                            }
//
//                            if !collapsed {
//                                ForEach(land.rides!) { ride in
//                                    RideCard(ride: ride)
//                                }
//                            }
                        }
                    }
                }
            }
            .task {
                loading.toggle()
                do {
                    results = try await getRides(parkId: parkId)
                    print(results!.lands.count)
                    print(results!.rides.count)
                } catch PTError.invalidUrl {
                    print("Invalid URL")
                } catch PTError.invalidResponse {
                    print("Invalid Response")
                } catch PTError.invalidData {
                    print("Invalid Data")
                } catch {
                    print("Unexpected Error")
                }
                loading.toggle()
            }
        }.scrollIndicators(.hidden)
    }
    
    func getRides(parkId: Int) async throws -> LandsAndRides {
        let endpoint = "https://queue-times.com/en-US/parks/\(parkId)/queue_times.json"
        
        guard let url = URL(string: endpoint) else {
            throw PTError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PTError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            //decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(LandsAndRides.self, from: data)
        } catch {
            throw PTError.invalidData
        }
    }
}

struct RideCard: View {
    @State var ride: RideModel
    var body: some View {
        VStack {
            HStack {
                Text(ride.name ?? "No Ride")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            VStack {
                HStack {
                    Text("Ride Status: \(ride.isOpen ?? false ? "Open" : "Closed")")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Wait Time: \(ride.waitTime ?? 0) min")
                        .font(.title)
                    
                }
                HStack {
                    Text("Last Updated: \(dateFormatter.date(from: ride.lastUpdated ?? "") ?? Date.now, style: .time)")
                }
            }
            
        }
        .frame(width: 340, height: 150)
        .background(ride.isOpen ?? false ? Color.green : Color.red)
        .cornerRadius(20)
        .shadow(color: ride.isOpen ?? false ? Color.green : Color.red, radius: 10)
        .padding()
    }
}

struct TestCard: View {
    @State var land: LandModel
    @State private var collapsed = false
    var body: some View  {
        VStack(alignment: .leading) {
            HStack {
                Text(land.name ?? "Test Land")
                    .font(.title2)
                    .bold()
                .foregroundColor(.blue)
                
                Button(action: {
                    withAnimation(collapsed == false ? .easeOut : .easeIn) {
                        collapsed.toggle()
                    }
                }, label: {
                    Text(collapsed == false ? "˯" : "^")
                        .font(.title)
                })
                
            }
        }
        
        if !collapsed {
            ForEach(land.rides!) { ride in
                RideCard(ride: ride)
            }
        }

    }

}



enum PTError: Error{
    case invalidUrl
    case invalidResponse
    case invalidData
}
