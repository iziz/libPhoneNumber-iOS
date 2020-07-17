//
//  FormatterView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import libPhoneNumber_iOS

struct FormatterView: View {
    @State var phoneNumber: String = ""
    let formatter: NBAsYouTypeFormatter = NBAsYouTypeFormatter(regionCode: Locale.current.regionCode)
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Phone Number")) {
                    TextField("Ex: 19091234567", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.largeTitle)
                        .padding()
                }
                .padding()
                Section(header: Text("Formatted Phone Number")) {
                    Text(formatPhoneNumber(phoneNumber: phoneNumber))
                }
            }
        }
        .navigationBarTitle("As-You-Type Formatter")
            .lineLimit(2)
            .multilineTextAlignment(.center)
    }
    
    func formatPhoneNumber(phoneNumber: String) -> String{
        self.formatter.clear()
        return formatter.inputString(phoneNumber)
    }
}

struct FormatterView_Previews: PreviewProvider {
    static var previews: some View {
        FormatterView()
    }
}
