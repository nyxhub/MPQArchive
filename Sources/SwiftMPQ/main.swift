//
//  main.swift
//  MPQSwift
//
//  Created by Gabriel Nica on 23/05/2017.
//  Copyright © 2017 Gabriel Nica.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import MPQArchive

var options = MPQArchiveLogOptions.debug

struct CommandLineArgument {
    var short: String
    var long: String
    var usage: String
    var isInput: Bool
    var action: () -> Void
    
    func description() -> String {
        return "\t\(short)\(long != "" ? ", \(long)" : "") - \(usage)"
    }
}

let showHeadersArg = CommandLineArgument(short: "-i", long: "--headers", usage: "Show user data header and MPQ header", isInput: false) {
    options.insert([.userDataHeader, .mpqHeader])
}

let hashTableArg = CommandLineArgument(short: "-h", long: "--hash-table", usage: "Show hash table", isInput: false) {
    options.insert(.hashTable)
}

let blockTableArg = CommandLineArgument(short: "-b", long: "--block-table", usage: "Show block table", isInput: false) {
    options.insert(.blockTable)
}

let listFileArg = CommandLineArgument(short: "-l", long: "--list-files", usage: "Show file list", isInput: false) {
    options.insert(.fileList)
}

let extractFilesArg = CommandLineArgument(short: "-x", long: "--extract", usage: "Extract files from the archive", isInput: false) {
    options.insert(.extraction)
}

let fileArg = CommandLineArgument(short: "file", long: "", usage: "File to load", isInput: true) {
    
}

let arguments = [fileArg, showHeadersArg, hashTableArg, blockTableArg, listFileArg, extractFilesArg]

func printUsage() {
    print("\u{001B}[1;37mExtracts files from an MPQ archive\u{001B}[0;37m")
    
    var usage = "\nusage: swiftmpq "
    
    for argument in arguments {
        usage += "\(argument.isInput ? "" : "[")\(argument.short)\(argument.isInput ? "" : "]") "
    }
    
    print(usage + "\n")
    
    for argument in arguments {
        print(argument.description())
    }
}

var filePath = ""
let args = [String](CommandLine.arguments[1 ..< CommandLine.arguments.count])
print("\u{001B}[1;37mSwiftMPQ v1.0\u{001B}[0;37m")

if args.count == 0 {
    printUsage()
    exit(0)
} else {
    var usedArgs = Set<String>()
    for option in args {
        if let argument = arguments.first(where: { $0.short == option || $0.long == option}) {
            argument.action()
            usedArgs.insert(option)
        }
    }
    
    let unusedArgs = usedArgs.symmetricDifference(args)
    
    if unusedArgs.count > 1 {
        printUsage()
    } else {
        if let fileArgument = unusedArgs.first {
            filePath = fileArgument
        }
    }
}

MPQArchive.logOptions = options

let replayURL = URL(fileURLWithPath: filePath)
do {
    let mpqArchive = try MPQArchive(fileURL: replayURL)
    
    if MPQArchive.logOptions.contains(.extraction) {
        try mpqArchive.extractFiles(toDisk: true)
    }
} catch (let error) {
    print("Error while reading file: \(error)")
}


