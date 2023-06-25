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

    public func injectIntoObject(_ value: [String : Any]) {
        if !inObject {
            error = "Illegal call to addIn: must be inside object"
            return
        }

        for key in value.keys.sorted(by: { $0 < $1 }) {
            guard let dvalue = value[key] else { continue }
            
            if let v = dvalue as? Int {
                write(v, forKey: key)
            }
            else if let v = dvalue as? Bool {
                write(v, forKey: key)
            }
            else if let v = dvalue as? String {
                write(v, forKey: key)
            }
            else if let v = dvalue as? Double {
                write(v, forKey: key)
            }
            else if let v = dvalue as? [String : Any] {
                write(v, forKey: key)
            }
            else if let v = dvalue as? [Any] {
                write(v, forKey: key)
            }
            else {
                let tdescr = type(of: dvalue)
                error = "Unable to write value of type \(tdescr) under key '\(key)'"
            }
        }
    }
    
    public func write(_ value: [String : Any], forKey key: String? = nil) {
        writeObject(forKey: key) {
            injectIntoObject(value)
        }
    }
    
    public func write(_ value: [Any], forKey key: String? = nil) {
        writeArray(forKey: key) {
            for a in value {
                if let v = a as? Int {
                    write(v)
                }
                else if let v = a as? Bool {
                    write(v)
                }
                else if let v = a as? String {
                    write(v)
                }
                else if let v = a as? Double {
                    write(v)
                }
                else if let v = a as? [String : Any] {
                    write(v)
                }
                else if let v = a as? [Any] {
                    write(v)
                }
                else {
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

public func doTest1() {
    let writer = SrjWriter()
    let d1: [String : Any] = ["negative" : -187,
                              "name" : ["abc", 18, 31.145, false],
                              "subDict" : ["sub1" : "foo",
                                           "sub2" : "bar"]]
    writer.writeObject {
        writer.write(32, forKey: "abc")
        writer.write("plugh", forKey: "ick")
        writer.write(d1, forKey: "nested")

        writer.writeObject(forKey: "subObject") {
            writer.write(-187, forKey: "negative")
            writer.write("abc", forKey: "name")
            writer.writeNull(forKey: "nullval")
        }
        writer.writeArray(forKey: "many") {
            writer.write(123)
            writer.write("blah")
            writer.write(false)
            writer.write(3.134)
            writer.writeArray {
                writer.write("abc")
                writer.write("xyz")
                writer.writeNull()
                writer.write(d1)
            }
        }
    }
    
    do {
        let result = try writer.output()
        print(result)
    } catch {
        print("oops: \(error)")
    }
    
}
