//
//  PriorityQueue.swift
//  Huffman
//
//  Created by руслан карымов on 18.04.2022.
//

import Foundation

struct LinkedList<T> {
    class Node<T> {
        var value: T
        var next: Node? = nil
        
        init(_ value: T, _ next: Node? = nil) {
            self.value = value
            self.next = next
        }
    }
    
    var head: Node<T>?
    var tail: Node<T>?
    
    var count: Int = 0
    
    mutating func push(_ item: T) {
        head = Node(item, head)
        if tail == nil {
            tail = head
        }
        count += 1
    }
    
    mutating func add(_ item: T) {
        if (head == nil) {
            push(item)
            return
        }
        tail!.next = Node(item)
        tail = tail!.next
        count += 1
    }
    
    mutating func insert(_ item: T, _ index: Int) {
        if index == 0 {
            push(item)
            return
        }
        var curItem = head
        var prevItem: Node<T>? = nil
        var curIndex = 0
        while curItem != nil {
            if curIndex == index {
                prevItem?.next = Node(item, curItem)
                break
            }
            prevItem = curItem
            curItem = curItem?.next
            curIndex += 1
        }
    }
    
    mutating func remove(_ index: Int) {
        if index == 0 {
            head = head?.next
        }
        var curItem = head
        var prevItem: Node<T>? = nil
        var curIndex = 0
        while curItem != nil {
            if curIndex == index {
                prevItem?.next = curItem?.next
                break
            }
            prevItem = curItem
            curItem = curItem?.next
            curIndex += 1
        }
    }
}

struct PriorityQueue<T> {
    var queue = LinkedList<(Int, T)>()
    
    mutating func enqueue(_ priority: Int, _ item: T) {
        var curItem = queue.head
        var curIndex = 0
        while curItem != nil {
            let val = curItem?.value
            if val!.0 > priority {
                queue.insert((priority, item), curIndex)
                return
            }
            curItem = curItem?.next
            curIndex += 1
        }
        queue.add((priority, item))
    }
    
    mutating func dequeue() -> (priority: Int, item: T)? {
        let result = queue.head
        queue.remove(0)
        return result?.value
    }
    
    var isEmpty: Bool {
        return queue.count == 0
    }
}
