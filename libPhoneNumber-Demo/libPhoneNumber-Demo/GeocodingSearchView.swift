//
//  GeocodingSearchView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import libPhoneNumber_iOS
import libPhoneNumberGeocoding

struct LocaleInfo {
    let localeCode: String
    let language: String
}

struct GeocodingSearchView: View {
    @State private var localeSelection = 0
    @State private var phoneNumber: String = ""
    @State private var regionDescription: String = ""
    
    let locales: [LocaleInfo] = [
        LocaleInfo(localeCode: "Default Device Language", language: "Default Device Language"),
        LocaleInfo(localeCode: "ar", language: "Arabic"),
        LocaleInfo(localeCode: "be", language: "Belarusian"),
        LocaleInfo(localeCode: "bg", language: "Bulgarian"),
        LocaleInfo(localeCode: "bs", language: "Bosnian"),
        LocaleInfo(localeCode: "de", language: "German"),
        LocaleInfo(localeCode: "el", language: "Greek"),
        LocaleInfo(localeCode: "en", language: "English"),
        LocaleInfo(localeCode: "es", language: "Spanish"),
        LocaleInfo(localeCode: "fa", language: "Persian"),
        LocaleInfo(localeCode: "fi", language: "Finnish"),
        LocaleInfo(localeCode: "fr", language: "French"),
        LocaleInfo(localeCode: "hr", language: "Croatian"),
        LocaleInfo(localeCode: "hu", language: "Hungarian"),
        LocaleInfo(localeCode: "hy", language: "Armenian"),
        LocaleInfo(localeCode: "id", language: "Indonesian"),
        LocaleInfo(localeCode: "it", language: "Italian"),
        LocaleInfo(localeCode: "iw", language: "Hebrew"),
        LocaleInfo(localeCode: "ja", language: "Japanese"),
        LocaleInfo(localeCode: "ko", language: "Korean"),
        LocaleInfo(localeCode: "nl", language: "Dutch"),
        LocaleInfo(localeCode: "pl", language: "Polish"),
        LocaleInfo(localeCode: "pt", language: "Portuguese"),
        LocaleInfo(localeCode: "ro", language: "Romanian"),
        LocaleInfo(localeCode: "ru", language: "Russian"),
        LocaleInfo(localeCode: "sq", language: "Albanian"),
        LocaleInfo(localeCode: "sr", language: "Serbian"),
        LocaleInfo(localeCode: "sv", language: "Swedish"),
        LocaleInfo(localeCode: "th", language: "Thai"),
        LocaleInfo(localeCode: "tr", language: "Turkish"),
        LocaleInfo(localeCode: "uk", language: "Ukrainian"),
        LocaleInfo(localeCode: "vi", language: "Vietnamese"),
        LocaleInfo(localeCode: "zh", language: "Chinese"),
        LocaleInfo(localeCode: "zh_Hant", language: "Chinese (Traditional)")
    ]
    
    private let geocoder = NBPhoneNumberOfflineGeocoder()
    private let phoneUtil = NBPhoneNumberUtil()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Locale Options")) {
                    Picker("Locale Options", selection: $localeSelection) {
                        ForEach(0 ..< locales.count) { index in
                            Text(self.locales[index].language)
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
            let parsedPhoneNumber: NBPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: Locale.current.regionCode!)
            if localeSelection == 0 {
                return geocoder.description(for: parsedPhoneNumber) ?? "Unknown Region"
            } else {
                return geocoder.description(for: parsedPhoneNumber, withLanguageCode: self.locales[localeSelection].localeCode) ?? "Unknown Region"
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
