//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  AppDelegate.swift
//  ScreenCapture
//
//  Created by Petri Damstén on 24.12.2015.
//  Copyright © 2015 Petri Damstén. All rights reserved.
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    let SC = "/usr/sbin/screencapture"
    let DEFAULTS = "/usr/bin/defaults"
    let KILLALL = "/usr/bin/killall"
    
    var destinationFolder = ""

    func saveName() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var s = formatter.stringFromDate(NSDate())
        formatter.dateFormat = "HH.mm.ss"
        s += " at " + formatter.stringFromDate(NSDate())
        return "/Screen Shot " + s + ".png"
    }

    func isDir(dir: String) -> Bool {
        var isDirectory: ObjCBool = ObjCBool(false)
        if NSFileManager.defaultManager().fileExistsAtPath(dir, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return true
            }
        }
        return false
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "statusIcon")
        icon?.template = true
        
        statusItem.image = icon
        statusItem.menu = statusMenu
        destinationFolder = execute(DEFAULTS, params: ["read", "com.apple.screencapture", "location"])
        if !isDir(destinationFolder) {
            destinationFolder = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0]
        }
    }

    func execute(cmd: String, params: [String]) -> String {
        //print(cmd, params)
        let task = NSTask()
        let pipe = NSPipe()
        
        task.launchPath = cmd
        task.arguments = params
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var output: String = (NSString(data: data, encoding: NSUTF8StringEncoding) as? String)!
        output = output.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        //print(output)
        return output
    }
    
    @IBAction func quitClicked(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func selectDestinationClicked(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = NSLocalizedString("Note: This changes directory also for the system wide shortcuts.", comment: "")
        panel.directoryURL = NSURL(string: destinationFolder)
        panel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.destinationFolder = (panel.URL?.path)!
                self.execute(self.DEFAULTS, params: ["write", "com.apple.screencapture", "location", self.destinationFolder])
                self.execute(self.KILLALL, params: ["SystemUIServer"])
            }
        }
    }
    
    @IBAction func captureWindowClicked(sender: AnyObject) {
        execute(SC, params: ["-i", "-W", "-o", destinationFolder + saveName()])
    }
    
    @IBAction func captureAreaClicked(sender: AnyObject) {
        execute(SC, params: ["-i", destinationFolder + saveName()])
    }
    
    @IBAction func captureScreenClicked(sender: NSMenuItem) {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue()) {
            self.execute(self.SC, params: [self.destinationFolder + self.saveName()])
        }
    }
}

