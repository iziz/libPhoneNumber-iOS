//
//  ContentView.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: GeocodingView()) {
                    Text("Geocoding")
                }
                NavigationLink(destination: PhoneUtilView()) {
                    Text("Phone Number Parser")
                }
                NavigationLink(destination: FormatterView()) {
                    Text("Phone Number Formatter")
                }
            }
            .navigationBarTitle("libPhoneNumber-iOS")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
