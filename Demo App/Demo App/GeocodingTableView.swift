//
//  GeocodingTableView.swift
//  Demo App
//
//  Created by Rastaar Haghi on 7/8/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import libPhoneNumber_iOS
import libPhoneNumberGeocoding

struct GeocodingTableView: View {
    // Keep track of runtime statistics
    var maxRuntime: CGFloat = 0.00
    var minRuntime: CGFloat = 0.00
    var totalRuntime: CGFloat = 0.00
    var averageRuntime: CGFloat = 0.00
    
    init() {
        for _ in 1...50 {
            makeGeocodingAPICalls()
        }
        
        self.maxRuntime = runtimeArray.max() ?? 0.0
        self.minRuntime = runtimeArray.min() ?? 0.0
        self.totalRuntime = 0.00
        for i in 0..<500 {
            self.totalRuntime += runtimeArray[i]
            runtimeArray[i] = runtimeArray[i]/maxRuntime
        }
        self.averageRuntime = totalRuntime / CGFloat(runtimeArray.count)
    }
    var body: some View {
        VStack {
            Form {
                Section(header: Text("This table makes 500 Geocoding API calls per page refresh.")) {
                    List {
                        ForEach(regionDescriptions, id: \.self) { pair in
                            HStack {
                                Text(pair[0]!)
                                Spacer()
                                Text(pair[1]!)
                            }
                        }
                    }
                }
            }
            Form {
                Section(header: Text("Runtime Performance for Geocoding API Calls")) {
                    LineGraph(dataPoints: runtimeArray)
                        .stroke(Color.green, lineWidth: 2)
                        .aspectRatio(16/9, contentMode: .fit)
                        .border(Color.gray, width: 1)
                        .padding()
                }
                Section(header: Text("Statistics for Runtime Performance (in milliseconds)")) {
                    List {
                        Text("Average API Call Runtime: \(round(averageRuntime).description)")
                        Text("Longest API Call Runtime: \(round(maxRuntime).description)")
                        Text("Shortest API Call Runtime: \(round(minRuntime).description)")
                        Text("Total Runtime: \(round(totalRuntime).description)")
                    }
                }
            }
        }
        .navigationBarTitle("Large Set of Geocoding Calls")
    }
}

struct GeocodingTableView_Previews: PreviewProvider {
    static var previews: some View {
        GeocodingTableView()
    }
}

extension GeocodingTableView {
    // Fetch Geocoding info for each number in phoneNumbers
    func makeGeocodingAPICalls() {
        var parsedPhoneNumber: NBPhoneNumber
        for phoneNumber in phoneNumbers {
            do {
                let startTimer = DispatchTime.now()
                parsedPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: "US")
                regionDescriptions.append([phoneNumber, geocoder.description(for: parsedPhoneNumber)])
                let endTimer = DispatchTime.now()
                runtimeArray.append(CGFloat(endTimer.uptimeNanoseconds - startTimer.uptimeNanoseconds)/1000000.0)
            } catch let error {
                print(error)
            }
        }
    }
    
    // Graph Design based from: https://www.objc.io/blog/2020/03/16/swiftui-line-graph-animation/
    struct LineGraph: Shape {
        var dataPoints: [CGFloat]
        
        func path(in rect: CGRect) -> Path {
            func point(at ix: Int) -> CGPoint {
                let point = dataPoints[ix]
                let x = rect.width * CGFloat(ix) / CGFloat(dataPoints.count - 1)
                let y = (1-point) * rect.height
                return CGPoint(x: x, y: y)
            }
            
            return Path { p in
                guard dataPoints.count > 1 else { return }
                let start = dataPoints[0]
                p.move(to: CGPoint(x: 0, y: (1-start) * rect.height))
                for idx in dataPoints.indices {
                    p.addLine(to: point(at: idx))
                }
            }
        }
    }
}

let phoneNumbers: [String] = ["19098611758", "14159601234", "12014321234", "12034811234", "12067061234", "12077711234", "12144681234", "12158231234", "12394351234", "12534591234"]
private var geocoder: NBPhoneNumberOfflineGeocoder = NBPhoneNumberOfflineGeocoder()
private var phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
var regionDescriptions: [[String?]] = []
var runtimeArray: [CGFloat] = []
