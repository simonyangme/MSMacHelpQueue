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
    var webView: WKWebView!
    var finishedNavigationSignal: Signal<WKWebView, NoError>!
    var finishedNavigationSink: SinkOf<Event<WKWebView, NoError>>!
    var requestsSignalProducer: SignalProducer<Request, NoError>!
    
    override func loadView() {
//        super.loadView()
//        self.invalidateRestorableState()

        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        
        var url = NSURL(string:"https://www.makeschool.com/sa/admin")
        var req = NSURLRequest(URL:url!)
        self.webView!.loadRequest(req)
        
        // Send WKWebViews when web view finishes loading
        let (pipeSignal, pipeSink) = Signal<WKWebView, NoError>.pipe()
        finishedNavigationSignal = pipeSignal |> delay(4, onScheduler: QueueScheduler.mainQueueScheduler)
        finishedNavigationSink = pipeSink
        
        // Tries to hide unnecessary parts of the DOM
        timer(1, onScheduler: QueueScheduler.mainQueueScheduler).start(next: {_ in
            self.webView.evaluateJavaScript("document.getElementsByClassName('col-three-fifths mt0 mb0')[0].style.display = 'none'", completionHandler: nil)
        })
        
        timer(30, onScheduler: QueueScheduler.mainQueueScheduler).start(next: {_ in self.webView.reload() })
        
        requestsSignalProducer = SignalProducer {sink, disposable in
            var requests = [Request]()
            self.finishedNavigationSignal.observe(next: { webView in
                webView.evaluateJavaScript("document.getElementsByClassName('event-author-wrap mb2').length") { result, error in
                    if let resultCount = result as? Int {
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
                            |> on(started: {println("started")}, event: {e in println(e)} )
                        requestsSignal.start(sink)
                    }
                }
            })
        }
        
        requestsSignalProducer.start(next: { request in
            println(request)
            let notification = NSUserNotification()
            notification.title = request.name
            notification.subtitle = request.title
            notification.informativeText = request.question
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        })
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }

    @IBAction func refresh(sender: AnyObject) {
        webView.reload()
    }

}

extension ViewController: WKNavigationDelegate {
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if let url = webView.URL, lastPathComponent = url.lastPathComponent {
            switch lastPathComponent {
            case "login":
                println("login!")
                webView.evaluateJavaScript("document.forms[0].elements[2].value = 'fill.it.in@makeschool.com'", completionHandler:nil)
                webView.evaluateJavaScript("document.forms[0].elements[3].value=''", completionHandler:nil)
                webView.evaluateJavaScript("document.forms[0].elements[5].click()", completionHandler:nil)
            case "admin":
                sendNext(finishedNavigationSink, webView)
            default:
                println("unrecognized! \(lastPathComponent)")
            }
        }
    }
}

extension ViewController: NSUserNotificationCenterDelegate {
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
}
