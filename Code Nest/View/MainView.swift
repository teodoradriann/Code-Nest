//
//  ContentView.swift
//  Code Nest
//
//  Created by Teodor Adrian on 3/14/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject var viewModel: CodeNestViewModel
    @State private var code: String = ""
    @State private var displayedOutput: String = ""
    @State private var clickedError = false
    @State private var lineWithError = 0
    @State private var navBar: Bool = false
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .frame(width: navBar ? geometry.size.width / 20 : 0, height: geometry.size.height)
                        .foregroundColor(.black.opacity(0.3))
                        .blur(radius: 10)
                        .cornerRadius(5)
                        .animation(.easeInOut(duration: 0.2), value: navBar)
                    
                    if navBar {
                        VStack {
                            Button(action: { navBar.toggle() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .offset(y: 12)
                            
                            Spacer()
                            
                            Button(action: {
                                openPanel(code: $code, viewModel: viewModel)
                                
                            }) {
                                HStack {
                                    Image(systemName: "document.fill").foregroundColor(.white)
                                    Text("Open")
                                }
                            }
                            Button(action: {
                                viewModel.updateCode(code)
                                savePanel(filename: viewModel.fileName, viewModel: viewModel)
                            }) {
                                HStack {
                                    Image(systemName: "externaldrive.fill").foregroundColor(.white)
                                    Text("Save")
                                }
                            }
                            Button(action: {
                                viewModel.updateCode(code)
                                viewModel.runCode()
                                clickedError = false
                                lineWithError = 0
                            }) {
                                HStack {
                                    Image(systemName: "play.fill").foregroundColor(.white)
                                    Text("Run")
                                }
                            }
                            Button(action: {
                                viewModel.terminateProcess()
                            }) {
                                HStack {
                                    Image(systemName: "stop.fill").foregroundColor(.white)
                                    Text("Kill")
                                }
                            }
                            .disabled(!viewModel.running)
                            
                            Spacer()
                        }
                        .transition(.move(edge: .leading))
                        .animation(.easeInOut(duration: 0.3), value: navBar)
                    }
                }
                VStack {
                    Spacer()
                    HStack {
                        if !navBar {
                            Button(action: { navBar.toggle() }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .offset(y: -5)
                        }
                        VStack {
                            Text("Code Nest")
                                .font(.title)
                            Text(viewModel.fileName + ".swift")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                            .opacity(viewModel.running ? 1 : 0)
                            .padding()
                            .offset(y: -5)
                        
                        Spacer()
                        
                        Text("Output")
                            .font(.title)
                            .padding()
                            .offset(y: -5)
                    }
                    HStack {
                        Spacer()
                        styledTextEditor($code, geometry.size, $lineWithError)
                        output(.constant(viewModel.terminated ?
                                         "Process automatically terminated (buffer overloaded).\n\n\(viewModel.output)" :
                                            (viewModel.output.isEmpty == false ? "Compilation successful!\n\n\(viewModel.output)" : viewModel.error)), $clickedError, $lineWithError)
                        .frame(width: geometry.size.width / 4)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

func output(_ displayedOutput: Binding<String>, _ clickedError: Binding<Bool>, _ lineError: Binding<Int>) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.black.opacity(0.3))
            .border(Color(.gray), width: 2)
        ScrollView {
            Button(action: {
                lineError.wrappedValue = extractLine(text: displayedOutput.wrappedValue) ?? 0
                clickedError.wrappedValue = true
            }) {
                Text(displayedOutput.wrappedValue)
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(5)
    }
}


func styledTextEditor(_ text: Binding<String>, _ geometrySize: CGSize, _ lineError: Binding<Int>) -> some View {
    return ScrollView(.vertical) {
        HStack(alignment: .top) {
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(0..<text.wrappedValue.split(separator: "\n").count, id: \ .self) { index in
                    HStack {
                        if index + 1 == lineError.wrappedValue {
                            Text(">")
                                .foregroundColor(.red)
                                .offset(y: 0)
                        }
                        Text("\(index + 1)")
                            .foregroundColor(.gray)
                            .offset(y: 0)
                        
                    }
                }
                
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: geometrySize.height - 97)
                    .foregroundColor(.clear)
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .border(Color.gray, width: 2)
                    .autocorrectionDisabled(true)
                    .disableAutocorrection(true)
                
                highlightedText(text.wrappedValue)
                    .allowsHitTesting(false)
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .multilineTextAlignment(.leading)
                    .offset(x: 5)
            }
        }
    }
}


func highlightedText(_ input: String) -> Text {
    let keywords = ["func", "struct", "class", "import", "let", "var", "some", "if", "else", "for", "in", "while", "return", "print", "guard", "switch", "case", "default", "break", "continue", "do", "try", "catch"]
    let operators = ["+", "-", "*", "/", "=", "==", "!=", "<", ">", "<=", ">="]
    let numbersRegex = "[0-9]+"
    let functions = ["func", "sleep", "mutating"]
    
    let lines = input.components(separatedBy: .newlines)
    
    return lines.reduce(Text("") ) { partialResult, line in
        let regex = try! NSRegularExpression(pattern: "\\S+", options: [])
        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, options: [], range: range)
        let words = matches.map { String(line[Range($0.range, in: line)!]) }
        
        let lineText = words.reduce(Text("")) { result, word in
            let textColor: Color
            
            if keywords.contains(word) {
                textColor = .pink
            } else if operators.contains(word) {
                textColor = .blue
            } else if word.range(of: numbersRegex, options: .regularExpression) != nil {
                textColor = .yellow
            } else if functions.contains(word) {
                textColor = .brown
            } else {
                textColor = .primary
            }
            
            return result + Text("\(word) ").foregroundColor(textColor)
        }
        
        return partialResult + lineText + Text("\n")
    }
}


func extractLine(text: String) -> Int? {
    let lines = text.components(separatedBy: .newlines)
    
    for i in 1..<lines.count {
        if lines[i].contains("error") {
            let words = lines[i - 1].components(separatedBy: " ")
            return Int(words[1])
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

