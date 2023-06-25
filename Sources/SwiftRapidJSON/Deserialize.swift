//
//  Deserialize.swift
//  
//
//  Copyright © 2023 David Baraff. All rights reserved.
//

import Foundation
import SwiftRapidJSONCxx


fileprivate class ObjectOrArray {
    let isArray: Bool
    var array: [Any]! = [Any]()
    var object: [String : Any]!
    
    var currentObjectKey: String?
    var isObject: Bool { !isArray }

    init(asArray: Bool) {
        isArray = asArray
        if isArray {
            array = [Any]()
            array.reserveCapacity(10)
        }
        else {
            object = [String : Any]()
            object.reserveCapacity(20)
        }
    }
}

fileprivate class ParserContext {
    static func pc(_ ptr: UnsafeMutableRawPointer) -> ParserContext {
        ptr.assumingMemoryBound(to: ParserContext.self).pointee
    }

    func store<T>(_ value: T) -> Bool {
        guard let top = parseStack.last else {
            error("Top-level must be array or object")
            return false
        }
        
        if top.isArray {
            top.array.append(value)
        }
        else {
            guard let key = top.currentObjectKey else {
                error("Interal parse error: expected a key to store current value")
                return false
            }
            top.object[key] = value
            top.currentObjectKey = nil
        }

        return true
    }

    func startObject() -> Bool {
        parseStack.append(ObjectOrArray(asArray: false))
        return true
    }

    func setKey(_ key: String) -> Bool {
        guard let top = parseStack.last,
              top.isObject else {
            error("Internal error: key encountered, but not in an object")
            return false
        }
        top.currentObjectKey = key
        return true
    }

    func endObject() -> Bool {
        guard let top = parseStack.popLast(),
              top.isObject else {
            error("Internal error: object end but not in an object")
            return false
        }

        guard !parseStack.isEmpty else {
            rootValue = top.isArray ? top.array : top.object
            return true
        }

        if top.isArray {
            return store(top.array)
        }
        else {
            return store(top.object)
        }
    }

    func startArray() -> Bool {
        parseStack.append(ObjectOrArray(asArray: true))
        return true
    }

    func endArray() -> Bool {
        guard let top = parseStack.popLast(),
              top.isArray else {
            error("Internal error: array end but not in an array")
            return false
        }
        
        guard !parseStack.isEmpty else {
            rootValue = top.isArray ? top.array : top.object
            return true
        }

        if top.isArray {
            return store(top.array)
        }
        else {
            return store(top.object)
        }
    }

    func error(_ description: String) {
        errorDescription = description
    }

    var parseStack = [ObjectOrArray]()
    var errored: Bool { !errorDescription.isEmpty }
    var errorDescription = ""
    
    var rootValue: Any?
}

fileprivate func parser(_ ptr: UnsafeMutableRawPointer) -> ParserContext {
    ptr.assumingMemoryBound(to: ParserContext.self).pointee
}

@_cdecl("srj_store_bool")
public func srj_store_bool(_ ptr: UnsafeMutableRawPointer, _ value: CBool) -> CBool {
    parser(ptr).store(Bool(value))
}

@_cdecl("srj_store_int")
public func srj_store_int(_ ptr: UnsafeMutableRawPointer, _ value: CInt) -> CBool {
    parser(ptr).store(Int(value))
}

@_cdecl("srj_store_int64")
public func srj_store_int64(_ ptr: UnsafeMutableRawPointer, _ value: CLongLong) -> CBool {
    parser(ptr).store(Int(value))
}

@_cdecl("srj_store_double")
public func srj_store_double(_ ptr: UnsafeMutableRawPointer, _ value: CDouble) -> CBool {
    parser(ptr).store(Double(value))
}

@_cdecl("srj_store_string")
public func srj_store_string(_ ptr: UnsafeMutableRawPointer, _ value: UnsafeMutablePointer<CChar>) -> CBool {
    parser(ptr).store(String(cString: value))
}

@_cdecl("srj_store_null")
public func srj_store_null(_ ptr: UnsafeMutableRawPointer) -> CBool {
    parser(ptr).store(NSNull())
}

@_cdecl("srj_handle_key")
public func srj_handle_key(_ ptr: UnsafeMutableRawPointer, _ value: UnsafeMutablePointer<CChar>) -> CBool {
    parser(ptr).setKey(String(cString: value))
}

@_cdecl("srj_start_object")
public func srj_start_object(_ ptr: UnsafeMutableRawPointer) -> CBool {
    parser(ptr).startObject()
}

@_cdecl("srj_end_object")
public func srj_end_object(_ ptr: UnsafeMutableRawPointer) -> CBool {
    parser(ptr).endObject()
}

@_cdecl("srj_start_array")
public func srj_start_array(_ ptr: UnsafeMutableRawPointer) -> CBool {
    parser(ptr).startArray()
}

@_cdecl("srj_end_array")
public func srj_end_array(_ ptr: UnsafeMutableRawPointer) -> CBool {
    parser(ptr).endArray()
}

@_cdecl("srj_parse_error")
public func srj_parse_error(_ ptr: UnsafeMutableRawPointer, _ value: UnsafeMutablePointer<CChar>) {
    parser(ptr).error(String(cString: value))
}

public func runTest(_ input: String) {
    var pc = ParserContext();
    let now = Date()
    _ = deserialize_json_from_string(&pc, input)
    let delta = Date().timeIntervalSince(now)
    
    print("Deserialize took: \(delta)")
    if let rootValue = pc.rootValue as? [String : Any] {
        if let assets = rootValue["assets"] as? [Any] {
            print("Got \(assets.count) assets")
            for i in 0 ..< min(assets.count, 5) {
                print(assets[i])
                print("----------")
            }
        }
        // print(rootValue)
    }
    else {
        print("Oops:")
        print(pc.errorDescription)
    }
}
