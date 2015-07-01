//
//  ViewController.swift
//  MSMacHelpQueue
//
//  Created by Simon Yang on 6/30/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import Cocoa
import WebKit
import ReactiveCocoa

class ViewController: NSViewController {
    /// some web view
    @IBOutlet var webView: WebView!
    var finishedNavigationSignal: Signal<WebView, NoError>!
    var finishedNavigationSink: SinkOf<Event<WebView, NoError>>!
    var requestsSignalProducer: SignalProducer<Request, NoError>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.frameLoadDelegate = self
        self.webView.resourceLoadDelegate = self
        self.webView.mainFrameURL = "https://www.makeschool.com/sa/admin"
        
        // Send WKWebViews when web view finishes loading
        let (pipeSignal, pipeSink) = Signal<WebView, NoError>.pipe()
        finishedNavigationSignal = pipeSignal |> delay(4, onScheduler: QueueScheduler.mainQueueScheduler) |> throttle(2, onScheduler: QueueScheduler.mainQueueScheduler)
        finishedNavigationSink = pipeSink
        
        // Tries to hide unnecessary parts of the DOM
        timer(1, onScheduler: QueueScheduler.mainQueueScheduler).start(next: {_ in
            self.webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('col-three-fifths mt0 mb0')[0].style.display = 'none'")
        })
        
        // Reload page
        timer(60, onScheduler: QueueScheduler.mainQueueScheduler).start(next: {_ in
            self.webView.reload(nil)
        })
        
        requestsSignalProducer = SignalProducer {sink, disposable in
            var requests = [Request]()
            self.finishedNavigationSignal.observe(next: { webView in
                let resultCount = webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('event-author-wrap mb2').length")?.toInt()
                if let resultCount = resultCount {
                    var requestSignalProducers = [SignalProducer<RequestBundle, NoError>]()
                    for i in 0..<resultCount {
                        requestSignalProducers.append(SignalProducer { sink, disposable in
                            sendNext(sink, (webView, i, Request()))
                            sendCompleted(sink)
                        } |> extractNames |> extractTitles |> extractQuestions)
                    }
                    
                    let requestsSignal = SignalProducer<SignalProducer<RequestBundle, NoError>, NoError>(values: requestSignalProducers)
                        |> flatten(.Concat)
                        |> map { _, _, request in return request }
//                        |> on(started: {println("started")}, event: {e in println(e)} )
                        |> filter { request in
                            if !contains(requests, request) {
                                requests.append(request)
                                return true
                            } else {
                                return false
                            }
                        }
                    requestsSignal.start(sink)
                }
            })
        }
        
        requestsSignalProducer.start(next: { request in
//            println(request)
            let notification = NSUserNotification()
            notification.title = request.name
            notification.subtitle = request.title
            notification.informativeText = request.question
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        })
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }

    @IBAction func refresh(sender: AnyObject) {
        webView.reload(nil)
    }

}

extension ViewController {
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if let url = frame.dataSource?.request.URL, lastPathComponent = url.lastPathComponent {
            switch lastPathComponent {
            case "login":
                println("login!")
                webView.stringByEvaluatingJavaScriptFromString("document.forms[0].elements[2].value = 'fill.it.in@makeschool.com'")
                webView.stringByEvaluatingJavaScriptFromString("document.forms[0].elements[3].value=''")
                webView.stringByEvaluatingJavaScriptFromString("document.forms[0].elements[5].click()")
            case "admin":
                sendNext(finishedNavigationSink, sender)
            default:
                println("unrecognized! \(lastPathComponent)")
                break
            }
        }
    }
}

extension ViewController: NSUserNotificationCenterDelegate {
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
}
