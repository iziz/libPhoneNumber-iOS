//
//  GeocodingView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
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
