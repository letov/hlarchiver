//
//  Huffman.swift
//  Huffman
//
//  Created by руслан карымов on 18.04.2022.
//

import Foundation

class TreeNode {
    var left: TreeNode?
    var right: TreeNode?
    var byte: Int8?
    init(left: TreeNode?, right: TreeNode?, byte: Int8?) {
        self.left = left
        self.right = right
        self.byte = byte
    }
}

class Huffman: ArchiverProtocol {
    var root: TreeNode?
    var frequencyArr = [(Int8, Int)]()
    var codesTable = [Int8: BitsArr]()
    var mainBitsArr = BitsArr()
    
    func archivate(data: [Int8]) -> [Int] {
        compress(data: data)
        print("archivate | pack frequency table")
        let packFrequencyTable = packFrequencyTable()
        print("archivate | pack bits")
        let packMainBitsArr = packMainBitsArr()
        return packFrequencyTable + packMainBitsArr
    }
    
    func dearchivate(data: [Int]) -> [Int8]? {
        guard data.count > 0 else {
            return nil
        }
        let frequencyCount = data[0]
        guard data.count > frequencyCount else {
            return nil
        }
        print("archivate | unpack frequency table")
        unpackFrequencyTable(data: Array(data[0...frequencyCount]))
        print("archivate | unpack bits")
        unpackMainBitsArr(data: Array(data[(frequencyCount + 1)..<data.count]))
        return decompress()
    }
    
    func genFrequency(data: [Int8]) {
        var frequencyTable = [Int8: Int]()
        for byte in data {
            frequencyTable[byte] = (frequencyTable[byte] ?? 0) + 1
        }
        frequencyArr = frequencyTable.sorted(by: <)
    }
    
    func genTree() {
        root = nil
        var queue = PriorityQueue<TreeNode>()
        for (byte, prioritry) in frequencyArr {
            queue.enqueue(prioritry, TreeNode(left: nil, right: nil, byte: byte))
        }
        while !queue.isEmpty {
            let _right = queue.dequeue()
            let _left = queue.dequeue()
            guard let right = _right, let left = _left else {
                root = _right?.item ?? _left?.item
                return
            }
            let prioritry = right.priority + left.priority
            let node = TreeNode(left: left.item, right: right.item, byte: nil)
            queue.enqueue(prioritry, node)
        }
    }
    
    func getCode(byte: Int8) -> BitsArr? {
        return getCode(byte: byte, node: root)
    }
    
    func getCode(byte: Int8, node: TreeNode?) -> BitsArr? {
        guard let node = node else {
            return nil
        }
        if node.byte == byte {
            return BitsArr()
        }
        let _right = getCode(byte: byte, node: node.right)
        let _left = getCode(byte: byte, node: node.left)
        guard let nextBitsArr = _right ?? _left else {
            return nil
        }
        let bitFlow = _left != nil ? BitsArr(firstBit: false) : BitsArr(firstBit: true)
        bitFlow.add(bitFlow: nextBitsArr)
        return bitFlow
    }
    
    func genCodes() {
        codesTable.removeAll()
        for (byte, _) in frequencyArr {
            codesTable[byte] = getCode(byte: byte)
        }
    }
    
    func genMainBitsArr(data: [Int8]) {
        mainBitsArr.clear()
        for byte in data {
            if let bitFlow = codesTable[byte] {
                mainBitsArr.add(bitFlow: bitFlow)
            }
        }
    }
    
    func compress(data: [Int8]) {
        print("compress | generate frequency table")
        genFrequency(data: data)
        print("compress | generate tree")
        genTree()
        print("compress | generate codes")
        genCodes()
        genMainBitsArr(data: data)
    }
    
    func getByte(bitFlow: BitsArr) -> Int8? {
        guard let bit = bitFlow.bit(at: 0) else {
            return nil
        }
        guard let root = root else {
            return nil
        }
        let nextNode = bit ? root.right : root.left
        return getByte(bitFlow: bitFlow, node: nextNode, bitIndex: 1)
    }
    
    func getByte(bitFlow: BitsArr, node: TreeNode?, bitIndex: Int) -> Int8? {
        guard bitIndex <= bitFlow.count else {
            return nil
        }
        guard let node = node else {
            return nil
        }
        guard let bit = bitFlow.bit(at: bitIndex) else {
            return nil
        }
        guard node.byte == nil else {
            return node.byte!
        }
        let nextNode = bit ? node.right : node.left
        return getByte(bitFlow: bitFlow, node: nextNode, bitIndex: bitIndex + 1)
    }
    
    func decompress() -> [Int8]? {
        print("decompress | generate tree")
        genTree()
        var result = [Int8]()
        var bitFlow = BitsArr()
        print("decompress | decompress bits")
        for bitIndex in 0..<mainBitsArr.count {
            guard let bit = mainBitsArr.bit(at: bitIndex) else {
                return nil
            }
            bitFlow.add(bitFlow: BitsArr(firstBit: bit))
            if let byte = getByte(bitFlow: bitFlow) {
                result.append(byte)
                bitFlow = BitsArr()
            }
        }
        return result
    }

    // 11001100
    // 00000000 ... 0100101
    // 11001100 ... 0100101
    func saveInt8ToIntHight(int8: Int8, int: Int) -> Int {
        return int | Int(truncatingIfNeeded:(UInt(UInt8(truncatingIfNeeded: int8)) << (7 * Int8.bitWidth)))
    }
    
    func readInt8FromIntHight(int: Int) -> (Int8, Int) {
        var int8 = Int8.zero
        var int = int
        int8 = Int8(truncatingIfNeeded:int >> (7 * Int8.bitWidth))
        int <<= 8
        int >>= 8
        return (int8, int)
    }
    
    // frequencyArr: [Int8: Int]
    //                       | size
    // count: Int8 x 8       | 8
    //        byte  frequency
    // row 0: Int8  Int8 x 7 | 8
    // row 1: ...
    func packFrequencyTable() -> [Int] {
        var result = [Int]()
        result.append(frequencyArr.count)
        for (byte, frequency) in frequencyArr {
            result.append(saveInt8ToIntHight(int8: byte, int: frequency))
        }
        return result
    }
    
    func unpackFrequencyTable(data: [Int]) {
        frequencyArr.removeAll()
        var frequencyTable = [Int8: Int]()
        guard data.count > 0 else {
            return
        }
        let count = data[0]
        guard data.count == count + 1 else {
            return
        }
        for i in 1...count {
            let (byte, frequency) = readInt8FromIntHight(int: data[i])
            frequencyTable[byte] = frequency
        }
        frequencyArr = frequencyTable.sorted(by: <)
    }
    
    // countBit: Int
    // data: [Int]
    func packMainBitsArr() -> [Int] {
        var result = [Int]()
        result.append(mainBitsArr.count)
        result += mainBitsArr.storage
        return result
    }
    
    func unpackMainBitsArr(data: [Int]) {
        mainBitsArr.clear()
        guard data.count > 0 else {
            return
        }
        mainBitsArr.count = data[0]
        mainBitsArr.storage = data
        mainBitsArr.storage.removeFirst()
    }
}

