//
//  GeocodingSearchView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import libPhoneNumberGeocoding
import libPhoneNumber_iOS

struct GeocodingSearchView: View {
  @State private var localeSelection = 0
  @State private var phoneNumber: String = ""
  @State private var regionDescription: String = ""

  private let geocoder = NBPhoneNumberOfflineGeocoder()
  private let phoneUtil = NBPhoneNumberUtil()

  var body: some View {
    VStack {
      Form {
        Section(header: Text("Locale Options")) {
          Picker("Locale Options", selection: $localeSelection) {
            ForEach(0..<locales.count) { index in
              Text(locales[index].language)
                .tag(index)
            }
          }
        }
        Section(header: Text("Phone Number")) {
          TextField("Ex: 19098611234", text: $phoneNumber)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
        Button(
          action: {
            self.regionDescription = self.searchPhoneNumber()
          },
          label: {
            Text("Search for Region Description")
              .multilineTextAlignment(.center)
          })
      }
      Text(regionDescription)
        .bold()
    }
    .navigationBarTitle(Text("Search for Region Description"))
  }
}

extension GeocodingSearchView {
  func searchPhoneNumber() -> String {
    do {
      let parsedPhoneNumber: NBPhoneNumber =
        try phoneUtil.parse(phoneNumber, defaultRegion: Locale.current.regionCode!)
      if localeSelection == 0 {
        return geocoder.description(for: parsedPhoneNumber) ?? "Unknown Region"
      } else {
        return geocoder.description(
          for: parsedPhoneNumber,
          withLanguageCode: locales[localeSelection].localeCode)
          ?? "Unknown Region"
      }
    } catch {
      print(error)
      return "Error parsing phone number."
    }
  }
}

struct GeocodingSearchView_Previews: PreviewProvider {
  static var previews: some View {
    GeocodingSearchView()
  }
}
