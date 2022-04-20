//
//  LZWTests.swift
//  ArchiverTests
//
//  Created by руслан карымов on 18.04.2022.
//

import XCTest
import CryptoKit

class LZWTests: XCTestCase {
    
    var lzw: LZW!
    var lzwArchiver: ArchiveFile!

    override func setUpWithError() throws {
        try super.setUpWithError()
        lzw = LZW()
        lzwArchiver = ArchiveFile(archiver: lzw)
    }

    override func tearDownWithError() throws {
        lzw = nil
        lzwArchiver = nil
        try super.tearDownWithError()
    }
    
    func testRemoveZeroBits() throws {
        XCTAssertEqual([8,17,72623859790382856,651345242494996240,0],
                       lzw.removeZeroBits(data: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,0], stride: 8))
        XCTAssertEqual([4,17,72058697861431555,73184614948405511,74310532035379467,75436449122353423,0],
                       lzw.removeZeroBits(data: [256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,0], stride: 4))
    }
    
    func testRestoreZeroBits() throws {
        XCTAssertEqual([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,0],
                       lzw.restoreZeroBits(data: [8, 18, 72623859790382856, 651345242494996240, 1224979098644774912]))
        XCTAssertEqual([256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,0],
                       lzw.restoreZeroBits(data: [4,17,72058697861431555,73184614948405511,74310532035379467,75436449122353423,0]))
    }
    
    func testCompressDecompress() throws {
        let data = lzw.stringToBytes(string: "TOBEORNOTTOBEORTOBEORNOT")
        let dataCompressed = [4, 16, 23644237350436933, 22236875352571983, 23644997572231428, 74591981241958663, 0]
        XCTAssertEqual(dataCompressed, lzw.archivate(data: data))
        XCTAssertEqual(data, lzw.dearchivate(data: dataCompressed))
    }
    
    func testCompressDecompressFile() throws {
        let inFilePath = (#file as NSString).deletingLastPathComponent + "/dataset.txt"
        let outFilePathCompress = inFilePath + ".archivate_lzw"
        let outFilePathDecompress = inFilePath + ".dearchivate_lzw"
        try lzwArchiver.archiveFile(inFilePath: inFilePath, outFilePath: outFilePathCompress, blockSize: 1000000)
        try lzwArchiver.dearchiveFile(inFilePath: outFilePathCompress, outFilePath: outFilePathDecompress)
        var data = FileManager.default.contents(atPath: inFilePath)!
        let hash1 = SHA256.hash(data: data)
        data = FileManager.default.contents(atPath: outFilePathDecompress)!
        let hash2 = SHA256.hash(data: data)
        XCTAssertEqual(hash1, hash2)
    }
}
