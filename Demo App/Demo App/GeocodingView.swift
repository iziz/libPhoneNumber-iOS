//
//  GeocodingView.swift
//  Demo App
//
//  Created by Rastaar Haghi on 7/8/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI

struct GeocodingView: View {
    var body: some View {
        List {
            NavigationLink(destination: GeocodingTableView()) {
                Text("Table of Region Descriptions")
            }
            NavigationLink(destination: GeocodingSearchView()) {
                Text("Search for a phone number")
            }
        }
        .navigationBarTitle("Geocoding", displayMode: .inline)
    }
}

struct GeocodingView_Previews: PreviewProvider {
    static var previews: some View {
        GeocodingView()
    }
}
