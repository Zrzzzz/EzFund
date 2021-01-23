//
//  Extensions.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/23.
//

import Cocoa

extension String {
    func find(_ pattern: String, at group: Int = 1) -> String {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        } catch {
            print(error.localizedDescription)
            return ""
        }
        
        guard let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.count)) else {
            return ""
        }
        
        guard let range = Range(match.range(at: group), in: self) else {
            return ""
        }
        
        return String(self[range])
    }
    
    func findArray(_ pattern: String, at group: Int = 1) -> [String] {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        } catch {
            print(error.localizedDescription)
            return []
        }
        
        let matches = regex.matches(in: self, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: self.count))
        
        var array = [String]()
        for match in matches {
            guard let range = Range(match.range(at: group), in: self) else {
                return []
            }
            array.append(String(self[range]))
        }
        
        return array
    }
    
    // Good Alternative!
    func findArrays(_ pattern: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let matches = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
            
            return matches.map { match in
                return (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: self) else {
                        return ""
                    }
                    return String(self[range])
                }
            }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}

extension NSColor {
    static let environment = NSColor(named: NSColor.Name("environColor"))!
    
    static func hex(_ h: UInt32) -> NSColor {
        let r = (h >> 16) & 0x0000ff
        let g = (h >> 8) & 0x0000ff
        let b = (h) & 0x0000ff
        slogLevel = .Info
        SLogInfo("\(r) \(g) \(b)")
        return NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1.0)
    }
}

extension CGColor {
    static let environment = NSColor.environment.cgColor
}


