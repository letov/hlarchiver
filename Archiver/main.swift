//
//  main.swift
//  Huffman
//
//  Created by руслан карымов on 18.04.2022.
//

import Foundation
import ArgumentParser

Archiver.main()

struct Archiver: ParsableCommand {
    @Argument(help: "Archiver action: c(ompress), d(ecompress).")
    var action: String
    @Argument(help: "Input file path.")
    var inFilePath: String
    @Argument(help: "Output file path.")
    var outFilePath: String
    @Option(name: .shortAndLong, help: "Size of data block for compression.")
    var blockSize: Int = 1000000
    @Option(name: .shortAndLong, help: "Compress algorithm: h(uffman), (l)zw.")
    var algo: String = "h"
    func run() throws {
        guard ["c","d"].contains(action) else {
            print("Wrong action")
            return
        }
        guard ["h","l"].contains(algo) else {
            print("Wrong algo")
            return
        }
        let archiverAlgo: ArchiverProtocol = "h" == algo ? Huffman() : LZW()
        let archiveFile = ArchiveFile(archiver: archiverAlgo)
        if "c" == action {
            try archiveFile.archiveFile(inFilePath: inFilePath, outFilePath: outFilePath, blockSize: blockSize)
        } else {
            try archiveFile.dearchiveFile(inFilePath: inFilePath, outFilePath: outFilePath)
        }
    }
}

protocol ArchiverProtocol {
    func archivate(data: [Int8]) -> [Int]
    func dearchivate(data: [Int]) -> [Int8]?
}

protocol ArchiveFileProtocol {
    init (archiver: ArchiverProtocol)
    func archiveFile(inFilePath: String, outFilePath: String, blockSize: Int) throws
    func dearchiveFile(inFilePath: String, outFilePath: String) throws
}

class ArchiveFile: ArchiveFileProtocol {
    let archiver: ArchiverProtocol
    let fileManager = FileManager.default

    required init(archiver: ArchiverProtocol) {
        self.archiver = archiver
    }

    func read(file: FileHandle, seekOffset: Int, readBufferSize: Int) throws -> Data? {
        let Int8Size = MemoryLayout<Int8>.size
        var data: Data?
        do {
            try file.seek(toOffset: UInt64(Int8Size * seekOffset))
            data = try file.read(upToCount: Int8Size * readBufferSize)
        }
        return data
    }
    
    func write(path: String, data: Data) throws {
        guard let file = FileHandle(forUpdatingAtPath: path) else {
            return
        }
        do {
            try file.seekToEnd()
            try file.write(contentsOf: data)
        }
    }
    
    func archiveFile(inFilePath: String, outFilePath: String, blockSize: Int) throws {
        guard let file = FileHandle(forUpdatingAtPath: inFilePath) else {
            return
        }
        let fileSize = try! FileManager.default.attributesOfItem(atPath: inFilePath)[.size] as! Int
        fileManager.createFile(atPath: outFilePath, contents: nil, attributes: nil)
        var seekOffset: Int = 0
        let readBufferSize = blockSize
        repeat {
            print("compressFile | seek: \(seekOffset), fileSize: \(fileSize)")
            do {
                guard let data = try read(file: file, seekOffset: seekOffset, readBufferSize: readBufferSize) else {
                    return
                }
                let bytes = data.reduce(into: [Int8]()) {
                    $0.append(Int8(bitPattern: $1))
                }
                var archived = archiver.archivate(data: bytes)
                archived = [archived.count] + archived
                let dataWrite = archived.withUnsafeBufferPointer {
                    Data(buffer: $0)
                }
                try write(path: outFilePath, data: dataWrite)
            }
            seekOffset += readBufferSize
        } while seekOffset < fileSize
        let sizeOrig = try FileManager.default.attributesOfItem(atPath: inFilePath)[.size] as! Int
        let sizeCompressed = try  FileManager.default.attributesOfItem(atPath: outFilePath)[.size] as! Int
        let effective: Float = ((Float(sizeOrig) - Float(sizeCompressed)) / Float(sizeOrig)) * 100.0
        print("effective | \(effective)")
    }

    func dearchiveFile(inFilePath: String, outFilePath: String) throws {
        let IntSize = MemoryLayout<Int>.size
        guard let file = FileHandle(forUpdatingAtPath: inFilePath) else {
            return
        }
        let fileSize = try! FileManager.default.attributesOfItem(atPath: inFilePath)[.size] as! Int
        fileManager.createFile(atPath: outFilePath, contents: nil, attributes: nil)
        var seekOffset: Int = 0
        var dearchivedCount: Int = 0
        repeat {
            print("decompressFile | seek: \(seekOffset), fileSize: \(fileSize)")
            do {
                guard let dataCount = try read(file: file, seekOffset: seekOffset, readBufferSize: IntSize) else {
                    return
                }
                dearchivedCount = dataCount.withUnsafeBytes {
                    $0.load(as: Int.self)
                }
                seekOffset += IntSize
                let readBufferSize = dearchivedCount * IntSize
                guard let data = try read(file: file, seekOffset: seekOffset, readBufferSize: readBufferSize) else {
                    return
                }
                let bytes: [Int] = data.withUnsafeBytes {
                    let unsafeBufferPointer = $0.bindMemory(to: Int.self)
                    let unsafePointer = unsafeBufferPointer.baseAddress!
                    return [Int](UnsafeBufferPointer<Int>(start: unsafePointer, count: dearchivedCount))
                }
                seekOffset += readBufferSize
                guard let dearchived = archiver.dearchivate(data: bytes) else {
                    return
                }
                let dataWrite = dearchived.withUnsafeBufferPointer {
                    Data(buffer: $0)
                }
                try write(path: outFilePath, data: dataWrite)
            }
        } while seekOffset < fileSize
    }
}
