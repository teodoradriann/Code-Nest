//
//  CodeNest.swift
//  Code Nest
//
//  Created by Teodor Adrian on 3/14/25.
//

import Foundation
import Darwin

private let maxOutputLength = 16384

struct CodeNest {
    private(set) var code: String?
    private(set) var nameOfFile: String = "untitled"
    private(set) var output: String?
    private(set) var errors: [String]?
    private(set) var path: URL?
    private(set) var running = false
    private(set) var terminated = false
    
    
    private var process: Process? = nil
    private var pipe: Pipe? = nil
    private var errorPipe: Pipe? = nil
    
    mutating func saveFile() {
        if path == nil {
            self.path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(nameOfFile + ".swift")
        }
        guard let url = path else { return }
        do {
            try code?.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    mutating func updateLocation(_ name: String, _ path: URL) {
        self.nameOfFile = String(name.split(separator: ".").first ?? "")
        self.path = path
    }
    
    mutating func runFileAsync(completion: @escaping (CodeNest) -> Void) {
        var runner = self
        runner.running = true
        runner.output = ""
        runner.errors = []
        runner.terminated = false
        
        DispatchQueue.main.async {
            completion(runner)
        }
        
        let newProcess = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        runner.pipe = pipe
        runner.errorPipe = errorPipe
        
        newProcess.standardOutput = pipe
        newProcess.standardError = errorPipe
        newProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        if let filePath = self.path?.path {
            newProcess.arguments = ["swift", filePath]
        } else {
            print("Error: No file path available")
            return
        }
        
        do {
            runner.process = newProcess
            try newProcess.run()
            
            DispatchQueue.global(qos: .background).async {
                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let outputData = handle.availableData
                    if !outputData.isEmpty, let newOutput = String(data: outputData, encoding: .utf8) {
                        runner.output = (runner.output ?? "") + newOutput
                        if runner.output?.count ?? 0 > maxOutputLength {
                            runner.terminated = true
                            runner.terminateProcess()
                        }
                        DispatchQueue.main.async {
                            completion(runner)
                        }
                    }
                }
            }
            
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let errorData = handle.availableData
                if !errorData.isEmpty, let newError = String(data: errorData, encoding: .utf8) {
                    runner.errors?.append(newError)
                    DispatchQueue.main.async {
                        completion(runner)
                    }
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                newProcess.waitUntilExit()
                runner.running = false
                runner.process = nil
                runner.pipe?.fileHandleForReading.readabilityHandler = nil
                runner.errorPipe?.fileHandleForReading.readabilityHandler = nil
                runner.pipe = nil
                runner.errorPipe = nil
                DispatchQueue.main.async {
                    completion(runner)
                }
            }
            self = runner
        } catch {
            print("Error running file: \(error)")
            runner.running = false
            runner.process = nil
            DispatchQueue.main.async {
                completion(runner)
            }
            self = runner
        }
    }
    
    mutating func terminateProcess() {
        guard process != nil, running else { return }
        if let process = process, process.isRunning {
            let pid = process.processIdentifier
            print(pid)
            process.terminate()
            process.waitUntilExit()
            if process.isRunning {
                print("Process did not terminate, forcing kill...")
                kill(pid_t(pid), SIGKILL)
            }
            self.pipe?.fileHandleForReading.readabilityHandler = nil
            self.errorPipe?.fileHandleForReading.readabilityHandler = nil
            self.pipe = nil
            self.errorPipe = nil
            self.process = nil
            self.running = false
            print("Process terminated successfully")
        } else {
            print("No process to terminate")
        }
    }
    
    mutating func updateCode(_ code: String) {
        self.code = code
    }
}

