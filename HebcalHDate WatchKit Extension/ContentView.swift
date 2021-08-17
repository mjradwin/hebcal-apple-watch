//
//  ContentView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        /*
        let cal2 = Calendar(identifier: Calendar.Identifier.hebrew)

        let now: Date = Date()

        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateStyle = .medium
        dateFormatter2.timeStyle = .none
        dateFormatter2.calendar = cal2
        let dateString2 = dateFormatter2.string(from: now)
 */
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
