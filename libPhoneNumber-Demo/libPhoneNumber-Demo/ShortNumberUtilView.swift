//
//  ShortNumberUtilView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/20/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import libPhoneNumber_iOS
import libPhoneNumberShortNumber
import SwiftUI

struct ShortNumberUtilView: View {
    @State private var phoneNumber: String = ""
    @State private var isValidShortNumber: Bool = false
    @State private var isEmergencyNumber: Bool = false
    @State private var estimatedCostOfCall: NBEShortNumberCost?
    @State private var searchMade: Bool = false

    let phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
    let shortNumberUtil: NBShortNumberUtil = NBShortNumberUtil()

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Phone Number")) {
                    TextField("Ex: 19098611234", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                Button(action: {
                    self.parsePhoneNumber()
                }, label: {
                    Text("Parse Short Number")
                })
            }
            if searchMade {
                if isValidShortNumber {
                    SuccessResultView
                } else {
                    FailedResultView
                }
            }
        }
        .navigationBarTitle(Text("Short Number Util Parser"))
    }

    var SuccessResultView: some View {
        Form {
            Section(header: Text("Phone Number Validation")) {
                Text("Valid Short Number ✅")
            }
            Section(header: Text("Emergency Number")) {
                if isEmergencyNumber {
                    Text(phoneNumber) + Text(" is an emergency number 🚨")
                } else {
                    Text(phoneNumber) + Text(" is not an emergency number")
                }
            }

            Section(header: Text("Expected Cost of Short Number")) {
                if estimatedCostOfCall == NBEShortNumberCost(rawValue: 1) {
                    Text("Toll Free Number")
                } else if estimatedCostOfCall == NBEShortNumberCost(rawValue: 2) {
                    Text("Standard Rate Number")
                } else if estimatedCostOfCall == NBEShortNumberCost(rawValue: 3) {
                    Text("Premium Rate Number")
                } else {
                    Text("Unknown Number Cost")
                }
            }
        }
    }

    var FailedResultView: some View {
        Form {
            Section(header: Text("Phone Number Validation")) {
                Text("Invalid Short Number ❌")
            }
        }
    }
}

extension ShortNumberUtilView {
    func parsePhoneNumber() {
        do {
            self.searchMade = true
            let parsedPhoneNumber: NBPhoneNumber =
                try phoneUtil.parse(self.phoneNumber, defaultRegion: Locale.current.regionCode!)
            self.isValidShortNumber = self.shortNumberUtil.isValidShortNumber(parsedPhoneNumber)
            self.isEmergencyNumber =
                self.shortNumberUtil.isEmergencyNumber(self.phoneNumber,
                                                       forRegion: Locale.current.regionCode!)
            self.estimatedCostOfCall = self.shortNumberUtil.expectedCost(of: parsedPhoneNumber)
        } catch {
            print(error)
        }
    }
}

struct ShortNumberUtilView_Previews: PreviewProvider {
    static var previews: some View {
        ShortNumberUtilView()
    }
}
