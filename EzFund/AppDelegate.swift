//
//  AppDelegate.swift
//  EzFund
//
//  Created by Zr埋 on 2021/1/22.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

//    var window: NSWindow!
    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    @IBOutlet weak var menu: NSMenu!
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
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
        // Create the SwiftUI view that provides the window contents.
//        let contentView = ContentView()
//
//        // Create the window and set the content view.
//        window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
//            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
//            backing: .buffered, defer: false)
//        window.isReleasedWhenClosed = false
//        window.center()
//        window.setFrameAutosaveName("Main Window")
//        window.contentView = NSHostingView(rootView: contentView)
//        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func mouseClickHandler(_ sender: Any?) {
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp {
                togglePopover(sender    )
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
        
    }
    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}

