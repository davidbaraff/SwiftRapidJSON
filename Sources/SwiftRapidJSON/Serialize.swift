//
//  Serialize.swift
//  
//
//  Copyright © 2023 David Baraff. All rights reserved.
//

import Foundation
import SwiftRapidJSONCxx

public struct SrjError : Error, CustomStringConvertible {
    private let details: String
    
    public init(_ details: String) {
        self.details = details
    }
    
    public var description: String {
        return details
    }
}


public class SrjWriter {
    let srjEncoder = SrjCreateEncoder()
    var inObjectStack = [false]
    
    public init() {
        
    }

    private func possiblyWriteKey(_ key: String?) -> Bool {
        guard error.isEmpty else { return false }
        if inObject {
            guard let key = key else {
                error = "no key specified while writing object"
                return false
            }
            SrjKey(srjEncoder, key)
        }
        else if let key = key {
            error = "unexpectedly found key '\(key)' while not writing object"
            return false
        }
        
        return true
    }

    public func write(_ value: Bool, forKey key: String? = nil) {
        guard possiblyWriteKey(key) else { return }
        SrjBool(srjEncoder, value);
    }

    public func write(_ value: Int, forKey key: String? = nil) {
        guard possiblyWriteKey(key) else { return }
        SrjInt(srjEncoder, Int32(value));
    }

    public func write(_ value: Double, forKey key: String? = nil) {
        guard possiblyWriteKey(key) else { return }
        SrjDouble(srjEncoder, value);
    }

    public func write(_ value: String, forKey key: String? = nil) {
        guard possiblyWriteKey(key) else { return }
        SrjString(srjEncoder, value)
    }

    private func writeOneValue(_ a: Any, forKey key: String?) -> Bool {
        switch ObjectIdentifier(type(of: a)) {
        case ObjectIdentifier(Int.self):
            if let v = a as? Int {
                write(v, forKey: key)
            }
            return true
        case ObjectIdentifier(String.self):
            if let v = a as? String {
                write(v, forKey: key)
            }
            return true
        case ObjectIdentifier(Bool.self):
            if let v = a as? Bool {
                write(v, forKey: key)
            }
            return true
        case ObjectIdentifier(Double.self):
            if let v = a as? Double {
                write(v, forKey: key)
            }
            return true
        case ObjectIdentifier([Any].self):
            if let v = a as? [Any] {
                write(v, forKey: key)
            }
            return true
        case ObjectIdentifier([String : Any].self):
            if let v = a as? [String: Any] {
                write(v, forKey: key)
            }
            return true
        default:
            ()
        }

        if let v = a as? Int {
            write(v, forKey: key)
            return true
        }
        else if let v = a as? Bool {
            write(v, forKey: key)
            return true
        }
        else if let v = a as? String {
            write(v, forKey: key)
            return true
        }
        else if let v = a as? Double {
            write(v, forKey: key)
            return true
        }
        else if let v = a as? [String : Any] {
            write(v, forKey: key)
            return true
        }
        else if let v = a as? [Any] {
            write(v, forKey: key)
            return true
        }
        return false
    }

    
    public func write(_ value: [String : Any], forKey key: String? = nil) {
        writeObject(forKey: key) {
            for key in value.keys.sorted(by: { $0 < $1 }) {
                guard let dvalue = value[key] else { continue }
                if !writeOneValue(dvalue, forKey: key) {
                    let tdescr = type(of: dvalue)
                    error = "Unable to write value of type \(tdescr) under key '\(key)'"
                }
            }
        }
    }
    
    public func write(_ value: [Any], forKey key: String? = nil) {
        writeArray(forKey: key) {
            for a in value {
                if !writeOneValue(a, forKey: nil) {
                    let tdescr = type(of: a)
                    error = "Unable to write value of type \(tdescr)"
                }
            }
        }
    }

    public func writeNull(forKey key: String? = nil) {
        guard possiblyWriteKey(key) else { return }
        SrjNull(srjEncoder)
    }
    
    public func writeArray(forKey key: String? = nil, _ code: () -> ()) {
        guard possiblyWriteKey(key) else { return }
        SrjStartArray(srjEncoder)
        inObjectStack.append(false)

        code()
        _ = inObjectStack.popLast()
        SrjEndArray(srjEncoder)
    }

    public func writeObject(forKey key: String? = nil, _ code: () -> ()) {
        guard possiblyWriteKey(key) else { return }
        SrjStartObject(srjEncoder)
        inObjectStack.append(true)

        code()
        _ = inObjectStack.popLast()
        SrjEndObject(srjEncoder)
    }

    public func output() throws -> String {
        guard error.isEmpty else {
            throw SrjError(error)
        }
        
        return String(cString: SrjGetOutput(srjEncoder))
    }

    var inObject: Bool { inObjectStack.last == true }
    var error = ""
    
    deinit {
        SrjDestroyEncoder(srjEncoder)
    }
}
