//
//  ContentView.swift
//  Filehole Mac
//
//  Created by skg on 9/20/22.
//

import SwiftUI
import FilePicker
import AppKit
import Alamofire

struct ContentView: View {
    @State private var urlLength: Int = 24
    @FocusState private var isFocused: Bool
    private let dateChoices: [String] = [
        "1 hour",
        "5 hours",
        "1 day",
        "39 hours",
        "2 days",
        "69 hours",
        "5 days"
    ]
    @State private var selectedDate: String = "1 day"
    @State private var selectedFilePath: String = ""
    @State private var isFileChosen: Bool = false
    @State private var fileHoleResponse: String = ""
    @State private var isFileBeingUploaded: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("URL Length (5-69)")
                TextField("", value: $urlLength, formatter: NumberFormatter())
                    .focused($isFocused)
                    .offset(x: 15, y:0)
                Stepper("", value: $urlLength, in: 5...69) {_ in
                    isFocused = false
                }
            }
            Picker("Expiry", selection: $selectedDate)
            {
                ForEach(dateChoices, id: \.self) {
                    Text($0)
                }
            }
            HStack {
                FilePicker(types: [.item], allowMultiple: false, title: "Choose File") { urls in
                    selectedFilePath = urls[0].path
                    isFileChosen = true
                }
                Image(nsImage: NSWorkspace.shared.icon(forFile: selectedFilePath))
                if isFileChosen {
                    Text(selectedFilePath.components(separatedBy: "/").last!)
                } else {
                    Text("no file chosen")
                }
                Spacer()
                Button("Upload") {
                    uploadFile()
                    selectedFilePath = ""
                    isFileChosen = false
                }.disabled(!isFileChosen)
            }
            if isFileBeingUploaded {
                ProgressView("Uploading...").progressViewStyle(.linear)
            } else if fileHoleResponse != "" {
                HStack {
                    Text(fileHoleResponse.trimmingCharacters(in: .whitespacesAndNewlines))
                        .lineLimit(1)
                        .fixedSize()
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(fileHoleResponse.trimmingCharacters(in: .whitespacesAndNewlines), forType: .string)
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                }
            }
        }
        .padding()
    }
    
    func uploadFile() {
        isFileBeingUploaded = true
        let dateChoiceTimeIntervals: [String] = [
            "3600",
            "18000",
            "86400",
            "140400",
            "172800",
            "248400",
            "432000"
        ]
    
        
        let expiryTime: String = dateChoiceTimeIntervals[   dateChoices.firstIndex(of: selectedDate)!]
        
        AF.upload(multipartFormData: { multiPartFormData in
            multiPartFormData.append(URL(fileURLWithPath: selectedFilePath), withName: "file")
            multiPartFormData.append(Data("\(expiryTime)".utf8), withName: "expiry")
            multiPartFormData.append(Data("\(urlLength)".utf8), withName: "url_len")
        }, to: "https://filehole.org")
        .response { resp in
            fileHoleResponse = String(decoding: resp.data!, as: UTF8.self)
            isFileBeingUploaded = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension Data {
    mutating func append(_ s: String) {
        self.append(s.data(using: .utf8)!)
    }
}

struct DecodableType: Decodable { let url: String }
