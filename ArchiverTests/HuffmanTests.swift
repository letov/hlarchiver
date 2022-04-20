//
//  HuffmanTests.swift
//  HuffmanTests
//
//  Created by руслан карымов on 18.04.2022.
//

import XCTest
import CryptoKit

class HuffmanTests: XCTestCase {
    
    var huffman: Huffman!
    var hoffmanArchiver: ArchiveFile!

    override func setUpWithError() throws {
        try super.setUpWithError()
        huffman = Huffman()
        hoffmanArchiver = ArchiveFile(archiver: huffman)
    }

    override func tearDownWithError() throws {
        huffman = nil
        hoffmanArchiver = nil
        try super.tearDownWithError()
    }
    
    func stringToBytes(string: String) -> [Int8] {
        return string.reduce(into: [Int8]()) {
            $0.append(Int8($1.asciiValue ?? 0))
        }
    }

    func testGetFrequency() throws {
        let data = stringToBytes(string: "AABBBCCCDDDDD")
        huffman.genFrequency(data: data)
        XCTAssertEqual(huffman.frequencyArr.count, 4)
    }
    
    func genString() -> String {
        var result = ""
        ["#:25","$:2",".:9","+:3","E:1"].forEach {
        //35     36    46    43    69
        //0      1100  10    111   1101
            let a = $0.components(separatedBy: ":")
            result += (0..<Int(a[1])!).reduce(into: "") { acc, _ in
                acc.append(a[0])
            }
        }
        return result
    }
    
    func genData() -> [Int8] {
        /*
         2 2 101
         0 5 00
         9 1 110
         3 2 100
         4 1 111
         1 5 01
         */
        return [0, 1, 1, 1, 1, 1, 3, 0, 3, 2, 2, 4, 0, 9, 0, 0]
    }
    
    func testCodes() throws {
        let data = stringToBytes(string: genString())
        huffman.genFrequency(data: data)
        huffman.genTree()
        let bitFlow = huffman.getCode(byte: 36)!
        XCTAssertEqual(bitFlow.asBinaryString, "1100")
    }
    
    func testGenMainBitsArr()  throws {
        var data = stringToBytes(string: genString())
        huffman.genFrequency(data: data)
        huffman.genTree()
        huffman.genCodes()
        data = stringToBytes(string: "##$$.E++")
        huffman.genMainBitsArr(data: data)
        XCTAssertEqual(huffman.mainBitsArr.asBinaryString,
                       "0011001100101101111111")
                   //   ^^^   ^   ^ ^   ^  ^
                   //   ##$   $   . E   +  +
        let string = (0..<1000).reduce(into: "") { acc, _ in
            acc.append(".") // 10
        }
        data = stringToBytes(string: string)
        huffman.genMainBitsArr(data: data)
        XCTAssertEqual(huffman.mainBitsArr.count, 1000 * 2)
    }

    func testCompressDecompress()  throws {
        let sourceData = stringToBytes(string: genString()) // 40 byte
        huffman.compress(data: sourceData)
        XCTAssertEqual(huffman.frequencyArr.count, 5) // 5 rows
        XCTAssertEqual(huffman.mainBitsArr.count, 64) // 8 byte
        let decompressData = huffman.decompress()!
        XCTAssertEqual(sourceData, decompressData)
    }
    
    func testSaveInt8ToIntHight() throws {
        let int8 = Int8(100)
        let int = Int(555555)
        XCTAssertEqual(huffman.saveInt8ToIntHight(int8: int8, int: int), 7205759403793349155)
    }
    
    func testReadInt8FromIntHight() throws {
        let int = Int(7205759403793349155)
        let (int8, newInt) = huffman.readInt8FromIntHight(int: int)
        XCTAssertEqual(int8, 100)
        XCTAssertEqual(newInt, 555555)
    }

    func testPackUnpackMainBitsArr() throws {
        let data = stringToBytes(string: genString())
        huffman.genFrequency(data: data)
        huffman.genTree()
        huffman.genCodes()
        huffman.genMainBitsArr(data: data)
        let origMainBitsArr = huffman.mainBitsArr
        let pack = huffman.packMainBitsArr()
        huffman.unpackMainBitsArr(data: pack)
        let unpackMainBitsArr = huffman.mainBitsArr
        XCTAssertEqual(origMainBitsArr, unpackMainBitsArr)
    }
    
    func testPackUnpack() throws {
        let data = stringToBytes(string: genString())
        let pack = huffman.archivate(data: data)
        let clearHuffman = Huffman()
        let unpack = clearHuffman.dearchivate(data: pack)
        XCTAssertEqual(data, unpack)
    }
    
    func testNewData() {
        let data: [Int8] = genData()
        let pack = huffman.archivate(data: data)
        let clearHuffman = Huffman()
        let unpack = clearHuffman.dearchivate(data: pack)
        XCTAssertEqual(huffman.mainBitsArr, clearHuffman.mainBitsArr)
        XCTAssertEqual(data, unpack)
    }
    
    func testCompressDecompressFile() throws {
        let inFilePath = (#file as NSString).deletingLastPathComponent + "/dataset.txt"
        let outFilePathCompress = inFilePath + ".archivate_hoffman"
        let outFilePathDecompress = inFilePath + ".dearchivate_hoffman"
        try hoffmanArchiver.archiveFile(inFilePath: inFilePath, outFilePath: outFilePathCompress, blockSize: 100000)
        try hoffmanArchiver.dearchiveFile(inFilePath: outFilePathCompress, outFilePath: outFilePathDecompress)
        var data = FileManager.default.contents(atPath: inFilePath)!
        let hash1 = SHA256.hash(data: data)
        data = FileManager.default.contents(atPath: outFilePathDecompress)!
        let hash2 = SHA256.hash(data: data)
        XCTAssertEqual(hash1, hash2)
    }
}
