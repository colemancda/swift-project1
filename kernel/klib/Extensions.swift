/*
 * kernel/klib/Extensions.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Misc extensions
 *
 */


extension String {

    // Convert a fixed length (not null terminated) raw string upto a
    // maximum length
    init(_ rawPtr: UnsafeRawPointer, maxLength: Int) {
        let ptr = rawPtr.bindMemory(to: UInt8.self, capacity: maxLength)
        let buffer = UnsafeBufferPointer(start: ptr, count: maxLength)
        var str = ""

        for ch in buffer {
            if ch != 0 {
                let us = UnicodeScalar(ch)
                if us.isASCII {
                    str += String(us)
                } else {
                    str += "?"
                }
            }
        }
        self = str
    }


    func components(separatedBy: Character) -> [String] {
        var result: [String] = []
        var element = ""
        for ch in self.characters {
            if ch == separatedBy {
                result.append(element)
                element = ""
            } else {
                element.append(ch)
            }
        }

        if element != "" {
            result.append(element)
        }

        return result
    }
}


extension UnsafePointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }

    // Increment a pointer by x bytes and recast to a new type
    // Unwrapped result as nil pointers cant be advanced
    func advancedBy<T>(bytes: Int) -> UnsafePointer<T> {
        return UnsafePointer<T>(bitPattern: UInt(bitPattern: self) + UInt(bytes))!
    }
}


extension UnsafeMutablePointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }

    // Increment a pointer by x bytes and recast to a new type
    // Unwrapped result as nil pointers cant be advanced
    func advancedBy<T>(bytes: Int) -> UnsafeMutablePointer<T> {
        return UnsafeMutablePointer<T>(bitPattern: UInt(bitPattern: self) + UInt(bytes))!
    }
}


extension UnsafeBufferPointer {
    func regionPointer<T>(offset: Int) -> UnsafePointer<T> {
        let max = offset + MemoryLayout<T>.stride
        assert(max <= self.count)
        let region = UInt(bitPattern: self.baseAddress) + UInt(offset)
        return UnsafePointer<T>(bitPattern: region)!
    }

#if os(Linux)
    func dumpBytes(count: Int) {
        self.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count, {
                hexDump(buffer: UnsafeBufferPointer<UInt8>(start: $0, count: count))
            })
    }
#endif
}


extension UnsafeRawPointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }
}


extension UnsafeMutableRawPointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }
}


/// Convert the given numeric value to a hexadecimal string.
public func asHex<T : SignedInteger>(_ x: T) -> String {
  return "0x" + String(Int(x), radix: 16)
}

public func asHex<T : UnsignedInteger>(_ x: T) -> String {
    return "0x" + String(UInt(x), radix: 16)
}


#if os(Linux)
private func hexDump(buffer: UnsafeBufferPointer<UInt8>) {

    func byteAsChar(value: UInt8) -> Character {
        if value >= 0x21 && value <= 0x7e {
            return Character(UnicodeScalar(value))
        } else {
            return "."
        }
    }

    var chars = ""
    for idx in 0..<buffer.count {
        if idx % 16 == 0 {
            if idx > 0 {
                print(chars)
                chars = ""
            }
            printf("%6.6X: ", idx)
        }
        printf("%2.2x ", buffer[idx])
        chars.append(byteAsChar(value: buffer[idx]))
    }
    let padding = 3 * (16 - chars.characters.count)
    if padding > 0 {
        print(String(repeating: " ", count: padding), terminator: "")
    }
    print(chars)
}
#endif
