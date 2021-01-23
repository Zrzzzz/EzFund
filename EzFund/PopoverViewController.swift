//
//  PopoverViewController.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/22.
//

import Cocoa
import Alamofire

class PopoverViewController: NSViewController {
    
    @IBOutlet weak var marketTableView: NSTableView!
    @IBOutlet weak var fundTableView: NSTableView!
    
    private var marketData: [Diff] = [] {
        didSet {
            self.marketTableView.reloadData()
        }
    }
    private var fundData: [Fund] = [
    ] {
        didSet {
            self.fundTableView.reloadData()
        }
    }
    
    private enum CellIdentifiers {
        static let fundName = "FundName"
        static let today = "TodayValue"
        static let yesterday = "YesterdayValue"
        
        static let marketName = "MarketName"
        static let newestValue = "NewestValue"
        static let udValue = "UDValue"
        static let udPercent = "UDPercent"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        refreshData()
    }
    func multiply(_ multiplicand:Int, multiplier:Int) -> Int {
        ENTRY_LOG()
        let result = multiplicand * multiplier
        EXIT_LOG()
        return result
    }
    private func setup() {
        fundTableView.dataSource = self
        fundTableView.delegate = self
        fundTableView.headerView?.layer?.backgroundColor = .environment
        fundTableView.backgroundColor = .environment
        
        marketTableView.dataSource = self
        marketTableView.delegate = self
        marketTableView.headerView?.layer?.backgroundColor = .environment
        marketTableView.backgroundColor = .environment
    }
    
    private func refreshData() {
        refreshFundData()
        refreshMarketData()
    }
    
    private func refreshFundData() {
        fundData = []
        for fundcode in Storage.fundcodes {
            let url = URL(string: "http://fundgz.1234567.com.cn/js/\(fundcode).js")!
            AF.request(url).response { (response) in
                //                print(response.response?.statusCode)
                switch response.result {
                case .success(let data):
                    if let data = data {
                        var jsonStr = String(data: data, encoding: .utf8) ?? ""
                        jsonStr = jsonStr.find("jsonpgz\\((.+)\\);")
                        let jsonData = jsonStr.data(using: .utf8)
                        let fund = try? JSONDecoder().decode(Fund.self, from: jsonData ?? Data())
                        if let fund = fund {
                            self.fundData.append(fund)
                        }
                    }
                case .failure(let err):
                    SLogError("failed to get fund data.\n \(err)")
                    
                    
                }
            }
        }
    }
    
    private func refreshMarketData() {
        marketData = []
        let url = URL(string: "http://73.push2.eastmoney.com/api/qt/clist/get?pn=1&pz=21&po=1&np=1&fltt=2&invt=2&fields=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f12,f13,f14,f15,f16,f17,f18,f20,f21,f23,f24,f25,f26,f22,f33,f11,f62,f128,f136,f115,f152,f124,f107&fs=i:1.000001,i:0.399001,i:0.399005,i:0.399006,i:1.000300")!
        AF.request(url).response { response in
            switch response.result {
            case .success(let data):
                if let data = data {
                    let market = try? JSONDecoder().decode(Market.self, from: data)
                    self.marketData = market?.data.diff ?? []
                }
            case .failure(let err):
                SLogError("failed to get Market Data.\n \(err)")
            }
        }
    }
}

extension PopoverViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == fundTableView {
            return fundData.count
        } else {
            return marketData.count
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == fundTableView {
            var text = ""
            var id = CellIdentifiers.fundName
            let color: NSColor = (Double(fundData[row].gszzl) ?? 0) > 0 ? NSColor.red : NSColor.hex(0x1a6840)
            let attributedString: (String) -> NSAttributedString = {(s: String) in
                return NSAttributedString(string: s,
                                          attributes: [
                                            NSAttributedString.Key.foregroundColor: color
                                          ])
            }
            
            if tableColumn == tableView.tableColumns[0] {
                text = fundData[row].name
                id = CellIdentifiers.fundName
                
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as? NSTableCellView {
                    cell.textField?.stringValue = text
                    return cell
                }
            } else if tableColumn == tableView.tableColumns[1] {
                id = CellIdentifiers.today
                
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as? NSTableCellView {
                    cell.textField?.attributedStringValue = attributedString(fundData[row].gsz + " " + fundData[row].gszzl + "%")
                    return cell
                }
            } else {
                id = CellIdentifiers.today
                
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as? NSTableCellView {
                    cell.textField?.attributedStringValue = attributedString(fundData[row].dwjz)
                    return cell
                }
            }
        } else {
            var text = ""
            var id = CellIdentifiers.marketName
            let market = marketData[row]
            let color: NSColor = market.f3 > 0 ? .red : NSColor.hex(0x1a6840)
            let attributedString: (String) -> NSAttributedString = {(s: String) in
                return NSAttributedString(string: s,
                                          attributes: [
                                            NSAttributedString.Key.foregroundColor: color
                                          ])
            }
            
            switch tableColumn {
            case tableView.tableColumns[0]:
                text = market.f14
                id = CellIdentifiers.marketName
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as? NSTableCellView {
                    cell.textField?.stringValue = text
                    return cell
                }
            case tableView.tableColumns[1]:
                text = String(format: "%.2f", market.f2)
                id = CellIdentifiers.newestValue
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as?
                    NSTableCellView {
                    cell.textField?.attributedStringValue = attributedString(text)
                    return cell
                }
            case tableView.tableColumns[2]:
                text = String(format: "%.2f", market.f4)
                id = CellIdentifiers.udValue
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as?
                    NSTableCellView {
                    cell.textField?.attributedStringValue = attributedString(text)
                    return cell
                }
            case tableView.tableColumns[3]:
                text = String(format: "%.2f%%", market.f3)
                id = CellIdentifiers.udPercent
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as?
                    NSTableCellView {
                    cell.textField?.attributedStringValue = attributedString(text)
                    return cell
                }
            default: break
            }
        }
        
        return nil
    }
}

extension PopoverViewController {
    static func freshController() -> PopoverViewController {
        //获取对Main.storyboard的引用
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        // 为PopoverViewController创建一个标识符
        let identifier = NSStoryboard.SceneIdentifier("PopoverViewController")
        // 实例化PopoverViewController并返回
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PopoverViewController else {
            fatalError("Something Wrong with Main.storyboard")
        }
        return viewcontroller
    }
}

