//
//  Helper.swift
//  MSMacHelpQueue
//
//  Created by Simon Yang on 6/30/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import Foundation
import ReactiveCocoa
import WebKit

typealias RequestBundle = (WKWebView, Int, Request)
typealias RequestBundleSignal = SignalProducer<RequestBundle, NoError>

func extractNames(input: RequestBundleSignal) -> RequestBundleSignal {
    return input |> flatMap(.Merge) { webView, index, request in
        return RequestBundleSignal() { sink, disposable in
            webView.evaluateJavaScript("document.getElementsByClassName('event-author-wrap mb2')[\(index)].getElementsByTagName('span')[0].innerHTML") { result, error in
                println(result)
                if let name = result as? String {
                    var newRequest = request
                    newRequest.name = name
                    sendNext(sink, (webView, index, newRequest))
                    sendCompleted(sink)
                } else {
                    sendCompleted(sink)
                }
            }
        }
    }
}

func extractTitles(input: RequestBundleSignal) -> RequestBundleSignal {
    return input |> flatMap(.Merge) { webView, index, request in
        return RequestBundleSignal() { sink, disposable in
            webView.evaluateJavaScript("document.getElementsByClassName('event-time mb1 mt0')[\(index)].innerHTML") { result, error in
//                println(result)
                if let questionTitle = result as? String {
                    var newRequest = request
                    newRequest.title = questionTitle
                    sendNext(sink, (webView, index, newRequest))
                    sendCompleted(sink)
                } else {
                    sendCompleted(sink)
                }
            }
        }
    }
}

func extractQuestions(input: RequestBundleSignal) -> RequestBundleSignal {
    return input |> flatMap(.Merge) { webView, index, request in
        return RequestBundleSignal() { sink, disposable in
            webView.evaluateJavaScript("document.getElementsByClassName('event-content pt2 mb2')[\(index)].getElementsByTagName('span')[0].getElementsByTagName('p')[0].innerHTML") { result, error in
                println(result)
                if let question = result as? String {
                    var newRequest = request
                    newRequest.question = question
                    sendNext(sink, (webView, index, newRequest))
                    sendCompleted(sink)
                } else {
                    sendCompleted(sink)
                }
            }
        }
    }
}
