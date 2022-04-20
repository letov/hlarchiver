//
//  BitsArr.swift
//  Huffman
//
//  Created by руслан карымов on 18.04.2022.
//

import Foundation

extension BinaryInteger {
    func bit(at index: Int) -> Bool {
        return (self >> index) & 1 == 1
    }
    
    mutating func setBit(at index: Int, to bool: Bool) {
        if bool {
        self |= (1 << index)
        } else {
        self &= ~(1 << index)
        }
    }
    var asBinaryString: String {
        var result = String()
        for i in 0..<self.bitWidth {
            result = (bit(at: i) ? "1" : "0") + result
        }
        return result
    }
}

class BitsArr: Equatable {
    var storage = [Int]()
    var count = 0
    
    init() {
    }
    
    init(firstBit: Bool) {
        var first = Int()
        if firstBit {
            first.setBit(at: Int.bitWidth - 1, to: true)
        }
        storage.append(first)
        count = 1
    }
    
    func clear() {
        storage = []
        count = 0
    }
    
    func add(bitFlow: BitsArr) {
        let newCount = count + bitFlow.count
        let (storageIndex, _) = getStorageIndex(index: newCount)
        while storageIndex >= storage.count {
            storage.append(0)
        }
        for storageValue in bitFlow.storage {
            for i in 0..<Int.bitWidth {
                if count >= newCount {
                    return
                }
                let bit = storageValue.bit(at: Int.bitWidth - i - 1)
                if bit {
                    let (storageIndex, bitIndex) =  getStorageIndex(index: count)
                    storage[storageIndex].setBit(at: Int.bitWidth - bitIndex - 1, to: true)
                }
                count += 1
            }
        }
    }

    var asBinaryString: String {
        return String(storage.reduce(into: "") { $0 += $1.asBinaryString }.prefix(count))
    }
    
    func getStorageIndex(index: Int) -> (storageIndex: Int, bitIndex: Int) {
        let storageIndex = Int(floor(Double(index) / Double(Int.bitWidth)))
        let bitIndex = index % Int.bitWidth
        return (storageIndex: storageIndex, bitIndex: bitIndex)
    }
    
    func bit(at index: Int) -> Bool? {
        let (storageIndex, bitIndex) = getStorageIndex(index: index)
        guard storageIndex < storage.count else {
            return nil
        }
        return storage[storageIndex].bit(at: Int.bitWidth - bitIndex - 1)
    }
    
    static func == (lhs: BitsArr, rhs: BitsArr) -> Bool {
        return lhs.storage == rhs.storage && lhs.count == rhs.count
    }
}
