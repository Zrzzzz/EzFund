//
//  SearchBar.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/23.
//

import SwiftUI
import AppKit

struct MySearchBar: View {
    @Binding var text: String
    
    var body: some View {
        VStack {
            SearchBar(text: $text)
        }
    }
}

struct SearchBar: NSViewRepresentable {
    @Binding var text: String
//    @Binding var isFocus: Bool
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchFieldDidStartSearching(_ sender: NSSearchField) {
            print("start")
        }
        
        func searchFieldDidEndSearching(_ sender: NSSearchField) {
            print("end")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }
}
