//
//  MainWindow.swift
//  
//
//  Created by Simon Yang on 6/30/15.
//
//

import Cocoa

class MainWindow: NSWindow {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.releasedWhenClosed = false
    }
    
    @IBAction func handleNewMainWindowMenu(sender: AnyObject) {
        self.makeKeyAndOrderFront(self)
    }
}
