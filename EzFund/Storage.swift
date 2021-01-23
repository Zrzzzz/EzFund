//
//  Storage.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/22.
//

import Cocoa

class Storage {
    static let fundcodes = ["005827"]
}

//MARK: - Fund
struct Fund: Codable {
    let fundcode, name, jzrq, dwjz: String
    let gsz, gszzl, gztime: String
}
     
// MARK: - Market
struct Market: Codable {
    let rc, rt, svr, lt: Int
    let full: Int
    let data: MarketData
}

// MARK: - MarketData
struct MarketData: Codable {
    let total: Int
    let diff: [Diff]
}

// MARK: - Diff
struct Diff: Codable {
    let f1: Int
    let f2, f3, f4: Double
    let f5, f6: Int
    let f7, f8: Double
    let f9: String
    let f10, f11: Double
    let f12: String
    let f13: Int
    let f14: String
    let f15, f16, f17, f18: Double
    let f20, f21: Int
    let f22: Double
    let f23: String
    let f24, f25: Double
    let f26: String
    let f33, f62, f107: Int
    let f115: String
    let f124: Int
    let f128, f140, f141, f136: String
    let f152: Int
}

