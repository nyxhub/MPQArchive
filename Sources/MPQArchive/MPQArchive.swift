//
//  MPQArchive.swift
//  SwiftMPQ
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
import zlib
import libbz2


let paddingLength = 30

public struct MPQFileFlags {
    static let implode: UInt32        = 0x00000100
    static let compress: UInt32       = 0x00000200
    static let encrypted: UInt32      = 0x00010000
    static let fixKey: UInt32         = 0x00020000
    static let singleUnit: UInt32     = 0x01000000
    static let deleteMarker: UInt32   = 0x02000000
    static let sectorCRC: UInt32      = 0x04000000
    static let exists: UInt32         = 0x80000000
}

public struct MPQHeader: CustomStringConvertible {
    var magic: UInt32 = 0// signature. MPQ0x1A
    var headerSize: UInt32 = 0 // Offset of the first file in the archive (practically the Header size)
    var archiveSize: UInt32 = 0
    var version: UInt16 = 0
    var blockSize: UInt16 = 0// Size of mpqFile block is 0x200 << BlockSize
    var hashTableOffset: UInt32 = 0
    var blockTableOffset: UInt32 = 0
    var hashTableEntries: UInt32 = 0
    var blockTableEntries: UInt32 = 0
    
    public var description: String {
        return "magic:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(String(magic, radix: 16, uppercase: true))\n" +
            "header size:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(headerSize)\n" +
            "archive size:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(archiveSize)\n" +
            "version:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(version)\n" +
            "block size:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(blockSize)\n" +
            "hash Table Offset:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(hashTableOffset)\n" +
            "block Table Offset:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(blockTableOffset)\n" +
            "hash Table Entries:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(hashTableEntries)\n" +
            "block Table Entries:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(blockTableEntries)\n"
    }
}

public struct MPQUserDataHeader: CustomStringConvertible {
    var magic: UInt32 = 0 // signature. MPQ0x1B
    var userDataSize: UInt32 = 0
    var mpqHeaderOffset: UInt32 = 0
    var mpqUserDataHeaderSize: UInt32 = 0
    
    public var description: String {
        return "magic:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(String(magic, radix: 16, uppercase: true))\n" +
            "user data size:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(userDataSize)\n" +
            "mpq header offset:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(mpqHeaderOffset)\n" +
            "mpq user data header size:".padding(toLength: paddingLength, withPad: " ", startingAt: 0) + "\(mpqUserDataHeaderSize)\n"
    }
}

public struct MPQHashTableEntry: CustomStringConvertible {
    var hashA: UInt32 = 0
    var hashB: UInt32 = 0
    var locale: UInt16 = 0
    var platform: UInt16 = 0
    var blockTableIndex: UInt32 = 0
    
    public var description: String {
        return String(hashA, radix: 16, uppercase: true).leftPadding(toLength: 8, withPad: "0") + " " +
            String(hashB, radix: 16, uppercase: true).leftPadding(toLength: 8, withPad: "0") + " " +
            String(locale, radix: 16, uppercase: true).leftPadding(toLength: 4, withPad: "0") + " " +
            String(platform, radix: 16, uppercase: true).leftPadding(toLength: 4, withPad: "0") + " " +
            String(blockTableIndex, radix: 16, uppercase: true).leftPadding(toLength: 8, withPad: "0")
    }
}

public struct MPQBlockTableEntry: CustomStringConvertible {
    var offset: UInt32 = 0
    var archivedSize: UInt32 = 0
    var size: UInt32 = 0
    var flags: UInt32 = 0
    
    public var description: String {
        return String(offset, radix: 16, uppercase: true).leftPadding(toLength: 8, withPad: "0") + " " +
            "\(archivedSize)".leftPadding(toLength: 8, withPad: " ") + " " +
            "\(size)".leftPadding(toLength: 8, withPad: " ") + " " +
            String(flags, radix: 16, uppercase: true).leftPadding(toLength: 8, withPad: "0")
    }
}

public enum TableEntryType: String {
    case hash = "hash"
    case block = "block"
}

public enum MPQHashType: UInt32 {
    case tableOffset = 0
    case hashA = 1
    case hashB = 2
    case table = 3
}

public enum CompressionType: UInt8, CustomStringConvertible {
    case uncompressed = 0
    case zlib = 2
    case bz2 = 16
    
    public var description: String {
        switch rawValue {
        case 0:  return "none"
        case 2:  return "zlib"
        case 16: return "bz2"
        default: return "?"
        }
    }
}

public struct MPQArchiveLogOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let none             = MPQArchiveLogOptions(rawValue: 1 << 0)
    public static let hashTable        = MPQArchiveLogOptions(rawValue: 1 << 1)
    public static let blockTable       = MPQArchiveLogOptions(rawValue: 1 << 2)
    public static let userDataHeader   = MPQArchiveLogOptions(rawValue: 1 << 3)
    public static let mpqHeader        = MPQArchiveLogOptions(rawValue: 1 << 4)
    public static let fileList         = MPQArchiveLogOptions(rawValue: 1 << 5)
    public static let extraction       = MPQArchiveLogOptions(rawValue: 1 << 6)
    public static let debug            = MPQArchiveLogOptions(rawValue: 1 << 7)
    
    public static let all: MPQArchiveLogOptions = [.hashTable, .blockTable, .userDataHeader, .mpqHeader, .fileList, .extraction, .debug]
}

public enum MPQArchiveError: Error {
    case unableToLoadListFile
    case unableToOpenMPQFile
    case notAnMPQFile
    case noFileProvided
    case fileAlreadyLoaded
}

private typealias DecompressionResult = (data: [Any], success: Bool, errorCode: Int32)

public final class MPQArchive {
    public static var logOptions: MPQArchiveLogOptions = .all
    
    private var fileURL: URL?
    var url: URL? {
        get {
            return fileURL
        }
    }
    var path: String {
        get {
            return fileURL?.path ?? ""
        }
    }
    
    private var mpqFile: UnsafeMutablePointer<FILE>? =  nil
    
    private var header = MPQHeader()
    private var userDataHeader = MPQUserDataHeader()
    
    private var hashTable = [MPQHashTableEntry]()
    private var blockTable = [MPQBlockTableEntry]()
    
    private var fileNames = [String]()
    public var fileList: [String] {
        get {
            if mpqFile != nil && MPQArchive.logOptions.contains(.debug) {
                print("MPQ file not loaded yet - file list will be empty. call .load() first")
            }
            return fileNames // it is possible for an MPQ to contain not files so returning this is fine
        }
    }
    
    private var encryptionTable: [UInt32]
    
    
    public init(fileURL: URL) throws {
        encryptionTable = MPQArchive.prepareEncryptionTable()
        try load(fileURL: fileURL)
    }
    
    public init() {
        encryptionTable = MPQArchive.prepareEncryptionTable()
    }
    
    
    public func load(fileURL: URL) throws {
        self.fileURL = fileURL
        
        if MPQArchive.logOptions.contains(.debug) {
            print("Loading MPQ Archive at path: \(fileURL.path)")
        }
        
        mpqFile = fopen(fileURL.path, "rb")
        
        guard mpqFile != nil else {
            if MPQArchive.logOptions.contains(.debug) { print("unable to open mpqFile") }
            throw MPQArchiveError.unableToOpenMPQFile
        }
        
        // Check if right type of mpqFile
        var magic: UInt32 = 0 //
        fread(&magic, MemoryLayout<UInt32>.size, 1, mpqFile)
        fseek(mpqFile, 0, SEEK_SET) // return to beginning of mpqFile
        
        func readInitialData() {
            hashTable = readTable(ofType: .hash)
            if MPQArchive.logOptions.contains(.hashTable) {
                print("\nMPQ archive hash table\n-----------------------")
                print(" Hash A   Hash B  Locl Plat BlockIdx\n")
                for entry in hashTable {
                    print(entry)
                }
            }
            
            blockTable = readTable(ofType: .block)
            if MPQArchive.logOptions.contains(.blockTable) {
                print("\nMPQ archive block table\n-----------------------")
                print(" Offset  ArchSize RealSize  Flags\n")
                for entry in blockTable {
                    print(entry)
                }
            }
            
            if MPQArchive.logOptions.contains(.debug) { print("\nExtracting list file ...\n") }
            if let listFile = readFile(filename: "(listfile)") as? [Int8] {
                fileNames = String(cString: listFile).components(separatedBy: "\r\n")
                
                if MPQArchive.logOptions.contains(.fileList) {
                    printFiles()
                }
            }
        }
        
        // if last byte is 0x1B then the mpqFile has a user data header
        if magic == 0x1a51504d {
            // MPQ\\x1a - single header (old archives)
            readHeader(offset: 0)
            readInitialData()
            fclose(mpqFile)
            mpqFile = nil
        } else if magic == 0x1b51504d {
            // MPQ\x1b - extended header
            // MPQ Header is located after the user header in the file
            readUserDataHeader()
            readHeader(offset: Int(userDataHeader.mpqHeaderOffset))
            readInitialData()
            fclose(mpqFile)
            mpqFile = nil
        } else {
            if MPQArchive.logOptions.contains(.debug) { print("file not an MPQ ARchive") }
            throw MPQArchiveError.notAnMPQFile
        }
        
    }
    
    @discardableResult
    public func extractFile(filename: String, writeToDisk: Bool) throws -> [Int8]? {
        guard let fileURL = fileURL else {
            throw MPQArchiveError.noFileProvided
        }
        
        if mpqFile == nil {
            mpqFile = fopen(fileURL.path, "rb")
            if mpqFile == nil {
                throw MPQArchiveError.unableToOpenMPQFile
            }
        }
        
        guard let fileData = readFile(filename: filename) as? [Int8] else {
            return nil
        }
        if writeToDisk {
            if let file = fopen(filename, "wb") {
                fwrite(fileData, MemoryLayout<Int8>.size, fileData.count, file)
                fclose(file)
            }
        }
        
        fclose(mpqFile)
        mpqFile = nil
        return fileData
    }
    
    public func extractFiles(toDisk: Bool) throws {
        if MPQArchive.logOptions.contains(.debug) {
            print("\nExtracting files ...\n")
            print("Name                      ArchSize       Type Comp     RealSize   Status")
            print("------------------------------------------------------------------------")
        }
        
        guard let fileURL = fileURL else {
            throw MPQArchiveError.noFileProvided
        }
        
        if mpqFile == nil {
            mpqFile = fopen(fileURL.path, "rb")
            if mpqFile == nil {
                throw MPQArchiveError.unableToOpenMPQFile
            }
        }
        
        for filename in fileNames {
            if filename != "" {
                try extractFile(filename: filename, writeToDisk: toDisk)
            }
        }
        
        fclose(mpqFile)
        mpqFile = nil
    }
    
    private func printFiles() {
        print("\nFiles\n-----")
        if let longestString = fileNames.max(by: {$1.characters.count > $0.characters.count}) {
            for filename in fileNames {
                if filename != "" {
                    if let hashEntry = getHashTableEntry(filename: filename) {
                        let blockEntry = blockTable[Int(hashEntry.blockTableIndex)]
                        print(filename.padding(toLength: longestString.characters.count, withPad: " ", startingAt: 0) +
                            " \(blockEntry.size)".leftPadding(toLength: 9, withPad: " ") + " bytes")
                    }
                }
            }
        }
    }
    
    private func readUserDataHeader() {
        fread(&userDataHeader, MemoryLayout<MPQUserDataHeader>.size, 1, mpqFile)
        
        if MPQArchive.logOptions.contains(.userDataHeader) {
            print("\nMPQ user data header\n-----------------------\n\(userDataHeader)")
        }
    }
    
    private func readHeader(offset: Int) {
        if offset > 0 {
            fseek(mpqFile, offset, SEEK_SET)
        }
        
        fread(&header, MemoryLayout<MPQHeader>.size, 1, mpqFile)
        
        if MPQArchive.logOptions.contains(.mpqHeader) {
            print("\nMPQ archive header\n-----------------------\n\(header)")
        }
    }
    
    
    // Read a hash or block table from an MPQ Archive
    private func readTable<T>(ofType type: TableEntryType) -> [T] {
        let offset = type == .hash ? header.hashTableOffset : header.blockTableOffset
        let numEntries = type == .hash ? header.hashTableEntries : header.blockTableEntries
        
        let key = hash(string: "(\(type.rawValue) table)", type: .table)
        
        fseek(mpqFile, Int(offset + userDataHeader.mpqHeaderOffset), SEEK_SET)
        
        var data = [UInt8](repeating: 0, count: Int(numEntries) * 16)
        fread(&data, MemoryLayout<UInt8>.size, Int(numEntries) * 16, mpqFile)
        data = decrypt(data, key: key)
        
        func unpackEntry<T>(position: Int) -> T {
            let entryData = data[position * 16 ..< position * 16 + 16]
            let entry = entryData.withUnsafeBufferPointer {
                ($0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) { $0 })
                }.pointee
            
            return entry
        }
        
        var entries = [T]()
        for i in 0 ..< numEntries {
            entries.append(unpackEntry(position: Int(i)))
        }
        return entries
        
        
    }
    
    private func decompress(fileAtOffset offset: Int, compressionType: CompressionType, compressedSize: UInt32, uncompressedSize: UInt32) -> DecompressionResult {
        
        switch compressionType {
        case .uncompressed:
            fseek(mpqFile, offset, SEEK_SET)
            var fileData = [Int8](repeating: 0, count: Int(uncompressedSize))
            let readBytes = fread(&fileData, MemoryLayout<Int8>.size, Int(compressedSize), mpqFile)
            
            return (data: fileData, success: readBytes > 0, errorCode: 1) // No compression
        case .zlib:
            
            var decompressedData = [UInt8](repeating: 0, count: Int(uncompressedSize))
            var uncompressedSize = uLongf(uncompressedSize)
            var compressedData = [UInt8](repeating: 0, count: Int(compressedSize))
            
            fseek(mpqFile, offset + 1, SEEK_SET)
            let readBytes = fread(&compressedData, MemoryLayout<UInt8>.size, Int(compressedSize), mpqFile)
            let result = uncompress(&decompressedData, &uncompressedSize, &compressedData, uLong(compressedSize))
            
            return (data: decompressedData, success: result == Z_OK && readBytes > 0, errorCode: result)
        case .bz2:
            var decompressedData = [Int8](repeating: 0, count: Int(uncompressedSize))
            var uncompressedSize = uncompressedSize
            var compressedData = [Int8](repeating: 0, count: Int(compressedSize))
            
            fseek(mpqFile, offset + 1, SEEK_SET)
            let readBytes = fread(&compressedData, MemoryLayout<UInt8>.size, Int(compressedSize), mpqFile)
            let result = BZ2_bzBuffToBuffDecompress(&decompressedData, &uncompressedSize, &compressedData, compressedSize, 0, 0)
            
            return (data: decompressedData, success: result == BZ_OK && readBytes > 0, errorCode: result)
        }
    }
    
    private func readFile(filename: String, forceDecompress: Bool = false) -> Any? {
        
        guard let hashEntry = getHashTableEntry(filename: filename) else {
            return nil
        }
        
        let blockEntry = blockTable[Int(hashEntry.blockTableIndex)]
        
        if blockEntry.flags & MPQFileFlags.exists > 0 {
            guard blockEntry.archivedSize != 0 else {
                return nil
            }
            
            let offset = blockEntry.offset + userDataHeader.mpqHeaderOffset
            fseek(mpqFile, Int(offset), SEEK_SET)
            
            var compressionTypeByte: UInt8 = 0
            fread(&compressionTypeByte, MemoryLayout<UInt8>.size, 1, mpqFile)
            guard let compressionType = CompressionType(rawValue: compressionTypeByte) else {
                return nil
            }
            
            if blockEntry.flags & MPQFileFlags.encrypted > 0 {
                //throw not supported
                return nil
            }
            
            if blockEntry.flags & MPQFileFlags.singleUnit == 0 {
                // File consists of multiple sectors. They need to be decompressed separately and united
                
                let sectorSize = 512 << header.blockSize
                var sectors = blockEntry.size / UInt32(sectorSize) + 1
                
                let crc: Bool
                if blockEntry.flags & MPQFileFlags.sectorCRC != 0 {
                    crc = true
                    sectors += 1
                } else {
                    crc = false
                }
                
                var positions = [UInt32](repeating: 0, count: Int(sectors) + 1)
                
                // not implemented yet
                return nil
                
            } else {
                if (blockEntry.flags & MPQFileFlags.compress != 0) && (forceDecompress || blockEntry.size > blockEntry.archivedSize) {
                    // Single unit files only need to be decompressed, but compression only happens when at least one byte is gained.
                    
                    var fileData = [Int8](repeating: 0, count: Int(blockEntry.archivedSize))
                    fread(&fileData, MemoryLayout<Int8>.size, Int(blockEntry.archivedSize), mpqFile)
                    
                    if MPQArchive.logOptions.contains(.debug) {
                        print(filename.padding(toLength: 25, withPad: " ", startingAt: 0) + " " +
                            "\(blockEntry.archivedSize)".leftPadding(toLength: 8, withPad: " ") + " bytes " +
                            "\(compressionType.rawValue)".leftPadding(toLength: 4, withPad: " ") + " " +
                            "\(compressionType)".leftPadding(toLength: 4, withPad: " ") + " ", terminator: "")
                    }
                    
                    let result = decompress(fileAtOffset: Int(offset), compressionType: compressionType, compressedSize: blockEntry.archivedSize, uncompressedSize: blockEntry.size)
                    
                    if MPQArchive.logOptions.contains(.debug) {
                        /*
                         // \u{001B}[\(attribute);\(colorcode)m
                         
                         // Color codes
                         // black   30
                         // red     31
                         // green   32
                         // yellow  33
                         // blue    34
                         // magenta 35
                         // cyan    36
                         // white   37
                         */
                        print("\(blockEntry.size)".leftPadding(toLength: 8, withPad: " ") + " bytes " +
                            "\(result.success ? "\u{001B}[0;32m  ✓   \u{001B}[0;37m" : "\u{001B}[0;31m  ✕   ")\u{001B}[0;37m")
                    }
                    
                    return result.data
                } else {
                    // even though file is marked as compressed, the compression gain is 0 so return the whole file
                    var fileData = [Int8](repeating: 0, count: Int(blockEntry.archivedSize))
                    fread(&fileData, MemoryLayout<Int8>.size, Int(blockEntry.archivedSize), mpqFile)
                    
                    return fileData
                }
            }
            
        }
        
        return nil
    }
    
    private func getHashTableEntry(filename: String) -> MPQHashTableEntry? {
        let hashA = hash(string: filename, type: .hashA)
        let hashB = hash(string: filename, type: .hashB)
        
        return hashTable.first(where: { $0.hashA == hashA && $0.hashB == hashB })
    }
    
    private class func prepareEncryptionTable() -> [UInt32] {
        // this is better off as a precomputed table like in libmpq
        
        var seed: UInt32 = 0x00100001
        var table = [UInt32](repeating: 0, count: 1280)
        
        for i in 0 ..< 256 {
            var index = i
            for _ in 0 ..< 5 {
                seed = (seed * 125 + 3) % 0x2AAAAB
                let temp1 = (seed & 0xFFFF) << 0x10
                
                seed = (seed * 125 + 3) % 0x2AAAAB
                let temp2 = (seed & 0xFFFF)
                
                table[index] = temp1 | temp2
                index += 0x100
            }
        }
        
        return table
    }
    
    private func hash(string: String, type: MPQHashType) -> UInt32 {
        var seed1: UInt32 = 0x7FED7FED
        var seed2: UInt32 = 0xEEEEEEEE
        
        for character in string.uppercased().characters {
            let codePoint = character.unicodeScalarCodePoint()
            let value = encryptionTable[Int(type.rawValue << 8 + codePoint)]
            
            seed1 = UInt32((UInt64(value) ^ (UInt64(seed1) + UInt64(seed2))) & 0xFFFFFFFF)
            seed2 = UInt32(truncatingIfNeeded: UInt64(codePoint) + UInt64(seed1) + UInt64(seed2) + (UInt64(seed2) << 5) + 3 & 0xFFFFFFFF)
            
        }
        
        return seed1
    }
    
    private func decrypt(_ data: [UInt8], key: UInt32) -> [UInt8] {
        var data = data
        var seed1 = key
        var seed2: UInt32 = 0xeeeeeeee;
        
        for i in stride(from: 0, to: data.count - 3, by: 4)
        {
            let temp = UInt64(seed2) + UInt64(encryptionTable[Int(0x400 + (seed1 & 0xff))])
            seed2 = UInt32(truncatingIfNeeded: temp)
            
            let array : [UInt8] = [data[i], data[i+1], data[i+2], data[i+3]]
            let littleEndianValue = array.withUnsafeBufferPointer {
                ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
                }.pointee
            let value = UInt32(littleEndian: littleEndianValue)
            
            var result: UInt32 = value
            
            result ^= seed1.addingReportingOverflow(seed2).0
            
            seed1 = (~seed1 << 21).addingReportingOverflow(0x11111111).0 | (seed1 >> 11)
            seed2 = result.addingReportingOverflow(seed2).0.addingReportingOverflow(seed2 << 5).0 + 3
            
            data[i + 0] = UInt8(result & 0xff)
            data[i + 1] = UInt8((result >> 8) & 0xff)
            data[i + 2] = UInt8((result >> 16) & 0xff)
            data[i + 3] = UInt8((result >> 24) & 0xff)
        }
        
        return data
    }
}


