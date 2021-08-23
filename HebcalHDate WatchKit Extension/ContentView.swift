//
//  ContentView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI
import os

struct ContentView: View {

    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ContentView", category: "Root View")

    var body: some View {
        VStack {
            Text("Hebcal")
                .font(.title)
                .fontWeight(.thin)
                .padding()
            Text("Jewish holiday calendars & Hebrew date converter")
                .fontWeight(.thin)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
