//
//  LZW.swift
//  Archiver
//
//  Created by руслан карымов on 18.04.2022.
//

import Foundation

typealias LZWCompressDictionary = [String: Int]
typealias LZWDecompressDictionary = [Int: String]

class LZW: ArchiverProtocol {
    
    let dictionarySizeStart = 256
    
    func archivate(data: [Int8]) -> [Int] {
        var dictionarySize = dictionarySizeStart
        var dictionary = genCompressDictionary(dictionarySize: dictionarySize)
        var current = ""
        var result = [Int]()
        for byte in data {
            let char = intToString(int: Int(byte))
            let enter = current + char
            if dictionary.keys.contains(enter) {
                current = enter
            } else {
                result.append(dictionary[current]!)
                dictionary[enter] = dictionarySize
                dictionarySize += 1
                current = char
            }
        }
        if !current.isEmpty {
            result.append(dictionary[current]!)
        }
        if !result.isEmpty {
            result = pack(data: result)
        }
        return result
    }
    
    func pack(data: [Int]) -> [Int] {
        let max = data.max()!
        if (max < Int8.max) {
            return removeZeroBits(data: data, stride: 8)
        } else if (max < Int16.max) {
            return removeZeroBits(data: data, stride: 4)
        } else if (max < Int32.max) {
            return removeZeroBits(data: data, stride: 2)
        }
        return data
    }
    
    func removeZeroBits(data: [Int], stride: Int) -> [Int] {
        var blockCount = 0
        let bitShift = Int(64 / stride)
        var newData = [Int]()
        var newInt = 0
        var curStride = stride - 1
        for int in data {
            newInt |= int << (curStride * bitShift)
            blockCount += 1
            curStride -= 1
            if (curStride < 0) {
                newData.append(newInt)
                newInt = 0
                curStride = stride - 1
            }
        }
        if blockCount != newData.count {
            newData.append(newInt)
        }
        newData = [stride, blockCount] + newData
        return newData
    }
    
    func restoreZeroBits(data: [Int]) -> [Int] {
        let stride = data[0]
        var blockCount = data[1]
        let bitShift = Int(64 / stride)
        var newData = [Int]()
        var newInt = 0
        var curStride = stride - 1
        for (key, int) in data.enumerated() where key > 1 {
            while curStride >= 0 {
                if (0 == blockCount) {
                    break
                }
                let leftShift = (stride - 1 - curStride) * bitShift
                let rightShift = curStride * bitShift
                newInt = int << leftShift
                newInt = newInt >> (leftShift + rightShift)
                newData.append(newInt)
                curStride -= 1
                blockCount -= 1
            }
            curStride = stride - 1
        }
        return newData
    }

    func dearchivate(data: [Int]) -> [Int8]? {
        let data = restoreZeroBits(data: data)
        var dictionarySize = dictionarySizeStart
        var dictionary = genDecompressDictionary(dictionarySize: dictionarySize)
        var current = String(Unicode.Scalar(UInt8(data[0])))
        var result = current
        for int in data[1..<data.count] {
            let entry: String
            if dictionary.keys.contains(int) {
                entry = dictionary[int]!
            } else if int == dictionarySize {
                entry = current + String(current[current.startIndex])
            } else {
                return nil
            }
            result += entry
            dictionary[dictionarySize] = current + String(entry[entry.startIndex])
            dictionarySize += 1
            current = entry
        }
        return stringToBytes(string: result)
    }
    
    func intToString(int: Int) -> String {
        String(Unicode.Scalar(UInt8(int)));
    }
    
    func stringToBytes(string: String) -> [Int8] {
        return string.reduce(into: [Int8]()) {
            $0.append(Int8($1.asciiValue ?? 0))
        }
    }
    
    func genCompressDictionary(dictionarySize: Int) -> LZWCompressDictionary {
        var dictionary = LZWCompressDictionary()
        for i in 0..<dictionarySize {
            let key = intToString(int: i)
            dictionary[key] = i
        }
        return dictionary
    }
    
    func genDecompressDictionary(dictionarySize: Int) -> LZWDecompressDictionary {
        var dictionary = LZWDecompressDictionary()
        for i in 0..<dictionarySize {
            dictionary[i] = intToString(int: i)
        }
        return dictionary
    }
}
 
