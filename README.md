# Swift MPQArchive

Swift MPQArchive is a cross platform native Swift port of the mpyq tool used in Blizzard Entertainment's
heroprotocol python library for extracting component files of a Heroes of the Storm
replay file. It can extract all or specific files contained in an MPQ archive both to disk or in memory. It comes in the form of an executable which can be used as is,
**swiftmpq** (the equivalent of **mpyq** python script) and a library, **MPQArchive**, which can be dynamically linked and used in software that needs to manipulate small MPQ archives, such as Starcraft 2 and Heroes of the Storm replay files. While faster than the python version it is a direct port and has
the same limitation - It shouldn't be used to extract large files so its use case should be limited to replay
files or otherwise small archives

Swift MPQArchive replicates the full functionality of the mpyq executable and library. The executable has the same interface and command line parameters as its python equivalent.

# Requirements

* Xcode 10+
* Swift 5.1 Toolchain
* ZLib C library
* BZip2 1.0.6 library installed with homebrew. Ensure that BZip2 is installed in `/usr/local/Cellar/bzip2/1.0.6_1`. If installed in different location you must modify the modulemap for bzip2

# Instalation

## Standalone

* Clone the repository locally
* run `swift build` in the clone folder or if you want to open and build the project in Xcode, `swift package generate-xcodeproj`

## As a library using Swift Package Manager

Add this dependency in your package description

```swift
  .package(url: "git@github.com:gabrielnica/MPQArchive.git", from: "1.0.0")
```



# MPQArchive Usage

To unarchive in memory:

```swift
let replayFileURL = URL(fileURLWithPath: "/Users/..../Infernal Shrines (60).StormReplay")
do {
    let archive = try MPQArchive(fileURL: replayFileURL)

    // by now the file is already loaded and MPQArchive extracted the file list.
    // If you don't want to do that and load the archive later
    // use let archive = MPQArchive(); [...] try archive.load(fileURL: replayFileURL)

    let data = try archive.extractFile(filename: "replay.message.events", writeToDisk: false)
} catch {
    print("Error while reading file: \(error)")
}
```

To access the list of files:

```swift
let archive = try MPQArchive(fileURL: replayFileURL)
let fileList = archive.fileList
```

To unarchive all files:

```swift
let archive = try MPQArchive(fileURL: replayFileURL)
for fileName in archive.fileList {
    let data = try archive.extractFile(filename: fileName, writeToDisk: false)
}

```

you can also unarchive all files directly using

```Swift
let archive = try MPQArchive(fileURL: replayFileURL)
let allFilesData = try archive.extractFiles(toDisk: false)

// allFilesData is a dictionary of format [filename: [UInt8]]

```

If extracting to disk you can specify the location by setting the archive's `public var extractLocation: URL?` property. Otherwise the current folder is assumed
