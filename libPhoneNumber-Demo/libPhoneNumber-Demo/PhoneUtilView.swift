//
//  PhoneUtilView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import libPhoneNumber_iOS
import libPhoneNumberGeocoding

struct PhoneUtilView: View {
    @State private var countryCode: String = ""
    @State private var nationalNumber: String = ""
    @State private var phoneNumber: String = ""
    @State private var isValidNumber: Bool = false
    @State private var searchMade: Bool = false
    @State private var formatSelection = 0
    @State private var formattedPhoneNumber: String = ""
    let phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Phone Number")) {
                    TextField("Ex: 19098611234", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                Section(header: Text("(Optional) Format Phone Number")) {
                    Picker("Locale Options", selection: $formatSelection) {
                        ForEach(0 ..< formatOptions.count) { index in
                            Text(formatOptions[index])
                                .tag(index)
                        }
                    }
                }
                
                Button(action: {
                    self.parsePhoneNumber()
                }, label: {
                    Text("Parse Phone Number")
                })
            }
            if searchMade {
                if isValidNumber {
                    SuccessResultView
                } else {
                    FailedResultView
                }
            }
        }
        .navigationBarTitle(Text("PhoneUtil Parser"))
    }
    
    var SuccessResultView: some View {
        Form {
            Section(header: Text("Phone Number Validation")) {
                Text("Valid Number ✅")
            }
            if formattedPhoneNumber != "" {
                Section(header: Text("Formatted Phone Number")) {
                    Text(self.formattedPhoneNumber)
                }
            }
            Section(header: Text("Country Code")) {
                Text(self.countryCode)
            }
            Section(header: Text("National Number")) {
                Text(self.nationalNumber)
            }
        }
    }
    
    var FailedResultView: some View {
        Form {
            Section(header: Text("Phone Number Validation")) {
                Text("Invalid Phone Number ❌")
            }
        }
    }
}

extension PhoneUtilView {
    func parsePhoneNumber() {
        do {
            self.searchMade = true
            let parsedPhoneNumber: NBPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: Locale.current.regionCode!)
            self.isValidNumber = phoneUtil.isValidNumber(parsedPhoneNumber)
            self.countryCode = parsedPhoneNumber.countryCode.stringValue
            self.nationalNumber = parsedPhoneNumber.nationalNumber.stringValue
            if formatSelection != 0 {
                self.formattedPhoneNumber = try phoneUtil.format(parsedPhoneNumber, numberFormat: NBEPhoneNumberFormat(rawValue: formatSelection-1)!)
            } else {
                self.formattedPhoneNumber = ""
            }
            
        } catch let error {
            print(error)
        }
    }
}

struct PhoneUtilView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneUtilView()
    }
}
