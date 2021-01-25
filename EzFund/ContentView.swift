//
//  ContentView.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/22.
//

import SwiftUI

struct ContentView: View {
    @Binding var text: String
    
    var body: some View {
        VStack {
            MySearchBar(text: $text)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(text: .constant("hahaha"))
    }
}
