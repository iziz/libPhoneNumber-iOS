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
    init() {
        for _ in 1..<100 {
            self.makeGeocodingAPICalls()
        }

    }
    var body: some View {
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
                parsedPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: "US")
                regionDescriptions.append([phoneNumber, geocoder.description(for: parsedPhoneNumber)])
            } catch let error {
                print(error)
            }
        }
    }
}

let phoneNumbers: [String] = ["19098611758", "14159601234", "12014321234", "12034811234", "12067061234", "12077711234", "12144681234", "12158231234", "12394351234", "12534591234"]
var geocoder: NBPhoneNumberOfflineGeocoder = NBPhoneNumberOfflineGeocoder()
var phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
var regionDescriptions: [[String?]] = []
