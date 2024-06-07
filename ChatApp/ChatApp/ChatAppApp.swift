//
//  ChatAppApp.swift
//  ChatApp
//
//  Created by Даниил Семёнов on 06.06.2024.
//

import SwiftUI

@main
struct ChatAppApp: App {
    var body: some Scene {
        WindowGroup {
//            ContentView(didComleteLoginProcess: {})
            MainMessagesView()
        }
    }
}
