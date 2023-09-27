//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  AppDelegate.swift
//  ScreenCapture
//
//  Created by Petri Damstén on 24.12.2015.
//  Copyright © 2015-2023 Petri Damstén. All rights reserved.
//  petri.damsten@gmail.com
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the
//  Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import Cocoa

// TODO: Add to login items

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!

    let SC = "/usr/sbin/screencapture"
    let DEFAULTS = "/usr/bin/defaults"
    let KILLALL = "/usr/bin/killall"
    
    var destinationFolder = ""

    func saveName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var s = formatter.string(from: Date())
        formatter.dateFormat = "HH.mm.ss"
        s += " at " + formatter.string(from: Date())
        return "/Screen Shot " + s + ".png"
    }

    func isDir(dir: String) -> Bool {
        var isDirectory: ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: dir, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return true
            }
        }
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.image = NSImage(named: "statusIcon")

        let statusBarMenu = NSMenu(title: "Cap Status Bar Menu")
        statusBarItem.menu = statusBarMenu

        let m1 = NSMenuItem(title: "Capture Screen\t⇧⌘3", action: #selector(AppDelegate.captureScreenClicked),
                             keyEquivalent: "")
        statusBarMenu.addItem(m1)
        let m2 = NSMenuItem(title: "Capture Window\t⇧⌘4 + Space", action: #selector(AppDelegate.captureWindowClicked), keyEquivalent: "")
        statusBarMenu.addItem(m2)
        let m3 = NSMenuItem(title: "Capture Area\t\t⇧⌘4", action: #selector(AppDelegate.captureAreaClicked),
                           keyEquivalent: "")
        statusBarMenu.addItem(m3)
        statusBarMenu.addItem(.separator())
        let m4 = NSMenuItem(title: "Select Destination...", action: #selector(AppDelegate.selectDestinationClicked),
                           keyEquivalent: "")
        statusBarMenu.addItem(m4)
        statusBarMenu.addItem(.separator())
        statusBarMenu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quitClicked),
                              keyEquivalent: "")
        
        destinationFolder = execute(cmd: DEFAULTS, params: ["read", "com.apple.screencapture", "location"])
        if !isDir(dir: destinationFolder) {
            destinationFolder = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
        }
    }

    @objc func quitClicked() {
        NSApplication.shared.terminate(self)
    }
    
    func execute(cmd: String, params: [String]) -> String {
        //print(cmd, params)
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = cmd
        task.arguments = params
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if var output = String(data: data, encoding: String.Encoding.utf8) {
            output = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            //print(output)
            return output
        }
        return "";
    }
    
    @objc func selectDestinationClicked(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = NSLocalizedString("Note: This changes directory also for the system wide shortcuts.", comment: "")
        panel.directoryURL = URL(string: destinationFolder)
        if (panel.runModal() ==  NSApplication.ModalResponse.OK) {
            self.destinationFolder = (panel.url?.path)!
            self.execute(cmd: self.DEFAULTS, params: ["write", "com.apple.screencapture", "location", self.destinationFolder])
            self.execute(cmd: self.KILLALL, params: ["SystemUIServer"])
        }
    }
    
    @objc func captureWindowClicked(sender: AnyObject) {
        execute(cmd: SC, params: ["-i", "-W", "-o", destinationFolder + saveName()])
    }
    
    @objc func captureAreaClicked(sender: AnyObject) {
        execute(cmd: SC, params: ["-i", destinationFolder + saveName()])
    }
    
    @objc func captureScreenClicked(sender: NSMenuItem) {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.execute(cmd: self.SC, params: [self.destinationFolder + self.saveName()])
        }
    }
}
