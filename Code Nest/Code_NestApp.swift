//
//  Code_NestApp.swift
//  Code Nest
//
//  Created by Teodor Adrian on 3/14/25.
//

import SwiftUI

@main
struct Code_NestApp: App {
    @State private var window: NSWindow?
    @StateObject var app = CodeNestViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: app)
                .onAppear {
                    DispatchQueue.main.async {
                        if let window = NSApp.mainWindow {
                            let screenFrame = NSScreen.main!.frame
                            window.setFrame(screenFrame, display: true)
                        }
                    }
                }
        }
    }
}
