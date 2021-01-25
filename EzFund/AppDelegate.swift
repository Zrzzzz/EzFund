//
//  AppDelegate.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/22.
//

import Cocoa
import SwiftUI
import Alamofire

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @IBOutlet weak var menu: NSMenu!
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initStatusItem()
        initWindow()
        initTimer()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    private func initTimer() {
        var times: Int = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { (_) in
            let fundData = Storage.retreive(LocalFileName.fund, from: .documents, as: LocalFund.self)?.fundData ?? []
            guard let button = self.statusItem.button else { return }
            if !fundData.isEmpty {
                button.imagePosition = .imageLeft
                let fund = fundData[times % fundData.count]
                let url = URL(string: "http://fundgz.1234567.com.cn/js/\(fund[0]).js")!
                AF.request(url).response { (response) in
                    //                print(response.response?.statusCode)
                    switch response.result {
                    case .success(let data):
                        if let data = data {
                            let jsonStr = String(data: data, encoding: .utf8)
                            if var jsStr = jsonStr {
                                jsStr = jsStr.find("jsonpgz\\((.+)\\);")
                                let jsonData = jsStr.data(using: .utf8)
                                let fund = try? JSONDecoder().decode(Fund.self, from: jsonData ?? Data())
                                if let fund = fund {
                                    button.attributedTitle = NSAttributedString(string: "\(fund.name) \(fund.gszzl)%", attributes: [NSAttributedString.Key.foregroundColor: ((Double(fund.gszzl) ?? 0) > 0 ? NSColor.hex(0xc21f30) : NSColor.hex(0x1a6840))])
                                }
                            } else {
                                button.attributedTitle = NSAttributedString(string: "\(fund[2]) 未知")
                            }
                        }
                    case .failure(let err):
                        SLogError("failed to get fund data.\n \(err)")
                        button.attributedTitle = .init(string: "")
                        button.imagePosition = .imageOnly
                        times = 0
                    }
                }
                times += 1
            } else {
                button.imagePosition = .imageLeft
                let url = URL(string: "http://73.push2.eastmoney.com/api/qt/clist/get?pn=1&pz=21&po=1&np=1&fltt=2&invt=2&fields=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f12,f13,f14,f15,f16,f17,f18,f20,f21,f23,f24,f25,f26,f22,f33,f11,f62,f128,f136,f115,f152,f124,f107&fs=i:1.000001,i:0.399001,i:0.399005,i:0.399006,i:1.000300")!
                AF.request(url).response { response in
                    switch response.result {
                    case .success(let data):
                        if let data = data {
                            let market = try? JSONDecoder().decode(Market.self, from: data)
                            if let marketData = market?.data.diff {
                                let market = marketData[times % marketData.count]
                                let color: NSColor = market.f3 > 0 ? .hex(0xc21f30) : NSColor.hex(0x1a6840)
                                button.attributedTitle = NSAttributedString(string: String(format: "%@ %.2f%%", market.f14, market.f3),
                                                                            attributes: [
                                                                                NSAttributedString.Key.foregroundColor: color
                                                                            ])
                            } else {
                                button.attributedTitle = NSAttributedString(string: "未获取到市场数据")
                            }
                        }
                    case .failure(let err):
                        SLogError("failed to get Market Data.\n \(err)")
                        button.attributedTitle = .init(string: "")
                        button.imagePosition = .imageOnly
                        times = 0
                    }
                }
                times += 1
            }
        }
        
        timer.fire()
    }
    
    private func initStatusItem() {
        statusItem.menu = nil
        menu.delegate = self
        
        if let button = statusItem.button {
            button.image = NSImage(named: "statusIcon")
            button.action = #selector(mouseClickHandler)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        popover.contentViewController = PopoverViewController.freshController()
        // 失去焦点消失
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: {  [weak self](event) in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.popover.performClose(event)
            }
        })
    }
    
    private func initWindow() {
        // for board
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.title = "控制台"
        window.contentViewController = BoardViewController.freshController()
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = true
    }
    
    @objc func mouseClickHandler(_ sender: Any?) {
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp {
                togglePopover(sender)
            } else if event.type == .rightMouseUp {
                statusItem.menu = menu
                statusItem.button?.performClick(nil)
            }
        }
    }
}
//MARK: - 左键菜单
extension AppDelegate {
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            ​closePopover(sender: sender)
        } else {
            ​showPopover(sender: sender)
        }
    }
    
    func ​showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }
    
    func ​closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}

//MARK: - 右键菜单
extension AppDelegate: NSMenuDelegate {
    @IBAction func openBoard(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        if let w = NSApp.windows.first(where: {$0 == window}) {
            w.makeKeyAndOrderFront(self)
        }
    }
    
    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}

