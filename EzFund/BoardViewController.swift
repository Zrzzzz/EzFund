//
//  BoardViewController.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/23.
//

import Cocoa
import Alamofire

class BoardViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchField: NSSearchField!

    @objc dynamic var searchResult: String = ""
    @objc dynamic var searchText: String = ""
    @objc dynamic var saveStatus: String = ""
    
    private var recentSearches: [String] = []
    private var foundFund: [String]?
    private var isFound: Bool = false
    private var totalFund: [[String]] = []
    var fundData: [[String]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private enum CellIdentifiers {
        static let codeCell = "SearchResultCodeCell"
        static let nameCell = "SearchResultNameCell"
    }
    
    
    lazy var searchesMenu: NSMenu = {
        
        let menu = NSMenu(title: "Recents")
        
        let recentTitleItem = menu.addItem(withTitle: "Recent Searches", action: nil, keyEquivalent: "")
        recentTitleItem.tag = Int(NSSearchField.recentsTitleMenuItemTag)
        
        let placeholder = menu.addItem(withTitle: "Item", action: nil, keyEquivalent: "")
        placeholder.tag = Int(NSSearchField.recentsMenuItemTag)
        
        menu.addItem( NSMenuItem.separator() )
        
        let clearItem = menu.addItem(withTitle: "Clear Menu", action: nil, keyEquivalent: "")
        clearItem.tag = Int(NSSearchField.clearRecentsMenuItemTag)
        
        let emptyItem = menu.addItem(withTitle: "No Recent Searches", action: nil, keyEquivalent: "")
        emptyItem.tag = Int(NSSearchField.noRecentsMenuItemTag)
        
        return menu
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        loadFundData()
    }
    
    override func viewWillAppear() {
        searchText = ""
        searchResult = ""
        saveStatus = ""
    }
    
    private func setup() {
        searchField.recentSearches = recentSearches
        searchField.searchMenuTemplate = searchesMenu
        searchField.placeholderString = "支持基金代码或基金名称"
        searchField.action = #selector(searchFund)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerForDraggedTypes([.rowDragType, .string])
        
        fundData = Storage.retreive(LocalFileName.fund, from: .documents, as: LocalFund.self)?.fundData ?? []
    }
    
    private func loadFundData() {
        AF.request(URL(string: "http://fund.eastmoney.com/js/fundcode_search.js")!).response { response in
            switch response.result {
            case .success(let data):
                if let data = data {
                    let jsonString = String(data: data, encoding: .utf8) ?? ""
                    let jsonData = jsonString.find("var r = (.+?);").data(using: .utf8) ?? Data()
                    self.totalFund = try! JSONDecoder().decode([[String]].self, from: jsonData)
                } else {
                    SLogError("no data.")
                }
            case .failure(let err):
                SLogError("can't load fund data.\n \(err)")
            }
        }
    }
    
    @objc private func searchFund() {
        guard !totalFund.isEmpty else {
            isFound = false
            return
        }
        if let fund = totalFund.first(where: { $0[0].contains(searchText) || $0[2].contains(searchText) }) {
            foundFund = fund
            isFound = true
            searchResult = "\(fund[0]) \(fund[2])"
        } else {
            searchResult = "无结果"
        }
    }
    
    @IBAction func addFund(_ sender: Any) {
        if isFound && !fundData.contains(foundFund!) {
            fundData.append(foundFund!)
        }
    }
    
    @IBAction func deleteRow(_ sender: Any) {
        let row: Int = tableView.selectedRow
        guard row != -1 else { return }
        
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(integer: row), withAnimation: .effectFade)
        tableView.endUpdates()
        fundData.remove(at: row)
    }
    
    @IBAction func saveResult(_ sender: Any) {
        Storage.store(LocalFund(fundData: fundData), in: .documents, as: LocalFileName.fund) {
            self.saveStatus = "保存成功！"
        } failure: {
            self.saveStatus = "保存失败！"
        }
    }
    
    
}

//MARK: - TableViewData
extension BoardViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        fundData.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let fund = fundData[row]
        let getCell = { (_ s: String) -> NSTableCellView? in
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: s), owner: nil) as? NSTableCellView
        }
        
        switch tableColumn {
        case tableView.tableColumns[0]:
            let cell = getCell(CellIdentifiers.codeCell)
            cell?.textField?.stringValue = fund[0]
            return cell
        case tableView.tableColumns[1]:
            let cell = getCell(CellIdentifiers.nameCell)
            cell?.textField?.stringValue = fund[2]
            return cell
        default: break
        }
        
        return nil
    }
}

extension BoardViewController {
    static func freshController() -> BoardViewController {
        //获取对Main.storyboard的引用
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        // 为PopoverViewController创建一个标识符
        let identifier = NSStoryboard.SceneIdentifier("BoardViewController")
        // 实例化PopoverViewController并返回
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? BoardViewController else {
            fatalError("Something Wrong with Main.storyboard")
        }
        return viewcontroller
    }
}
