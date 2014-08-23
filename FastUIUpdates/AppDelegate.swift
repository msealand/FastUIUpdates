//
//  AppDelegate.swift
//  FastUIUpdates
//
//  Created by Michael Sealand on 8/22/14.
//  Copyright (c) 2014 Michael Sealand. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var dataTextField: NSTextField!
    @IBOutlet weak var countTextField: NSTextField!

    var data: UInt64 = 0
    var uiUpdateCount: UInt64 = 0
    var uiTimer: NSTimer? = nil
    
    /* 
        How often to update the UI, in seconds.
    
        Feel free to play with this value and see what happens, 
        even 0.01 (~1/60th of a second) only uses ~4% CPU for 
        the UI thread on my machine.
    */
    var updateInterval: NSTimeInterval = 0.1
    
    // Create a serial queue for synchronized data access
    let dataAccessQueue = dispatch_queue_create("fastUIUpdates.dataAccessQueue", DISPATCH_QUEUE_SERIAL)
    
    func startup() {
        // Fire off an infinite while loop to update our data on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            [weak self] in // Make sure we don't create a strong reference cycle

            while (true) {
                /*
                    Dispatch an data update synchronously to the dataAccessQueue.
                    Since dataAccessQueue is serial, it'll only run one code block at
                    a time, in the order they're received. If we do all read and writes
                    to our data in the dataAccessQueue, there won't be any data
                    contention issues.
                */
                dispatch_sync(self?.dataAccessQueue) {
                    [weak self] in // Make sure we don't create a strong reference cycle
                    
                    // Our "data update" is just incrementing a counter
                    self?.data += 1
                    
                    /*
                        Since this closure only has one expression in it, we have to explicitly return.
                        Otherwise we'll run in to problems with swift's "Implicit Returns from Single-Expression Closures"
                        https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html#//apple_ref/doc/uid/TP40014097-CH11-XID_158
                    */
                    return
                }
            }
        }
        
        // Start the UI update timer on the main queue
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in // Make sure we don't create a strong reference cycle
            
            // Start the UI update timer; calls updateUI() once every updateInterval
            self?.uiTimer = NSTimer.scheduledTimerWithTimeInterval(self!.updateInterval, target: self!, selector: "updateUI", userInfo: nil, repeats: true)
            
            return
        }
    }
    
    func shutdown() {
        // Stop and release the UI update timer on the main queue
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in // Make sure we don't create a strong reference cycle
            self?.uiTimer?.invalidate()
            self?.uiTimer = nil
        }
    }
    
    func updateUI() {
        uiUpdateCount++
        
        // Dispatch the data read synchronously to the dataAccessQueue
        dispatch_sync(dataAccessQueue) {
            [weak self] in // Make sure we don't create a strong reference cycle
            self?.dataTextField.stringValue = "\(self!.data)" // Update the data update count label
            return
        }
        
        /*
            Update the UI update count label outside the dataAccessQueue block;
            we don't want to do more in there than we have to.
        */
        self.countTextField.stringValue = "\(uiUpdateCount)"
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        startup()
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // We don't technically need to call this here since the app is terminating, but it's good practice
        shutdown()
    }
}
