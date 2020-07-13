//
//  GeocodingSearchView.swift
//  Demo App
//
//  Created by Rastaar Haghi on 7/8/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import libPhoneNumber_iOS
import libPhoneNumberGeocoding

struct GeocodingSearchView: View {
    @State private var localeSelection = 0
    @State private var phoneNumber: String = ""
    @State private var regionDescription: String = ""

    let languages = ["Default Device Language", "Arabic", "Belarusian", "Bulgarian", "Bosnian", "German", "Greek", "English", "Spanish", "Persian", "Finnish", "French", "Croatian", "Hungarian", "Armenian", "Indonesian", "Italian", "Hebrew", "Japanese", "Korean", "Dutch", "Polish", "Portuguese", "Romanian", "Russian", "Albanian", "Serbian", "Swedish", "Thai", "Turkish", "Ukrainian", "Vietnamese", "Chinese", "Chinese (Traditional)"]

    let locales = ["Default Device Language", "ar", "be", "bg", "bs", "de", "el", "en", "es", "fa", "fi",  "fr", "hr", "hu", "hy", "id", "it", "iw", "ja", "ko", "nl", "pl", "pt", "ro", "ru", "sq", "sr", "sv", "th", "tr", "uk", "vi", "zh", "zh_Hant"]
    
    private let geocoder = NBPhoneNumberOfflineGeocoder()
    private let phoneUtil = NBPhoneNumberUtil()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Locale Options")) {
                    Picker("Locale Options", selection: $localeSelection) {
                        ForEach(0 ..< languages.count) { index in
                            Text(self.languages[index])
                                .tag(index)
                        }
                    }
                }
                Section(header: Text("Phone Number")) {
                    TextField("Ex: 19098611234", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                Button(action: {
                    self.regionDescription = self.searchPhoneNumber()
                }, label: {
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
            print(Locale.current.regionCode!)
            let parsedPhoneNumber: NBPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: Locale.current.regionCode!)
            print(parsedPhoneNumber)
            if localeSelection == 0 {
                return geocoder.description(for: parsedPhoneNumber) ?? "Unknown Region"
            } else {
                return geocoder.description(for: parsedPhoneNumber, withLanguageCode: locales[localeSelection]) ?? "Unknown Region"
            }
        } catch let error {
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
