//
//  FormatterView.swift
//  Demo App
//
//  Created by Rastaar Haghi on 7/10/20.
//  Copyright © 2020 Rastaar Haghi. All rights reserved.
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
                    TextField("Ex: 19098611758", text: $phoneNumber)
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
        .navigationBarTitle("NBAsYouTypeFormatter")
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
