//
//  CodeNestViewModel.swift
//  Code Nest
//
//  Created by Teodor Adrian on 3/14/25.
//

import Foundation
import SwiftUI

class CodeNestViewModel: ObservableObject {
    @Published private var codeRunner: CodeNest = CodeNest()
    
    func updateCode(_ code: String) {
        var newRunner = self.codeRunner
        newRunner.updateCode(code)
        self.codeRunner = newRunner
    }
    
    func runCode() {
        codeRunner.saveFile()
        codeRunner.runFileAsync { updatedRunner in
            DispatchQueue.main.async {
                self.codeRunner = updatedRunner
            }
        }
    }
    
    
    func terminateProcess() {
        DispatchQueue.global(qos: .background).async {
            var updated = self.codeRunner
            updated.terminateProcess()
            DispatchQueue.main.async {
                self.codeRunner = updated
            }
        }
    }
    
    func updateFileLocation(filename: String, path: URL) {
        codeRunner.updateLocation(filename, path)
        codeRunner.saveFile()
    }
    
    var running: Bool {
        codeRunner.running
    }
    
    var terminated: Bool {
        codeRunner.terminated
    }
    
    var output: String {
        codeRunner.output ?? ""
    }
    
    var errors: [String] {
        codeRunner.errors ?? []
    }
    
    var fileName: String {
        codeRunner.nameOfFile
    }
}
