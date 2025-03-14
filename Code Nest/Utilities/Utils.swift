//
//  Utils.swift
//  Code Nest
//
//  Created by Teodor Adrian on 3/14/25.
//

import Foundation
import SwiftUI


func extractLine(text: String) -> Int? {
    let lines = text.components(separatedBy: .newlines)
    for i in 1..<lines.count {
        if lines[i].contains("`-") {
            let words = lines[i - 1].components(separatedBy: " ")
            return Int(words[0])
        }
    }
    return nil
}

func savePanel(filename: String, viewModel: CodeNestViewModel) {
    let savePanel = NSSavePanel()
    savePanel.title = "Save Code"
    savePanel.canCreateDirectories = true
    savePanel.nameFieldStringValue = filename
    savePanel.allowedContentTypes = [.swiftSource]
    savePanel.begin { respone in
        if respone == .OK {
            guard let url = savePanel.url else { return }
            viewModel.updateFileLocation(filename: savePanel.nameFieldStringValue, path: url)
            print("File saved at: \(url.path)")
        }
    }
}


func openPanel(code: Binding<String>, viewModel: CodeNestViewModel) {
    let openPanel = NSOpenPanel()
    openPanel.title = "Open Code"
    openPanel.allowedContentTypes = [.swiftSource]
    openPanel.begin { response in
        if response == .OK {
            guard let url = openPanel.urls.first else { return }
            do {
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                print("File opened at: \(url.path)")
                code.wrappedValue = fileContent
                viewModel.updateFileLocation(filename: url.lastPathComponent, path: url)
            } catch {
                print("Error reading file: \(error)")
            }
        }
    }
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}

