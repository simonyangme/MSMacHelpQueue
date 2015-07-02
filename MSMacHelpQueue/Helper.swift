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

typealias RequestBundle = (WebView, Request)
typealias RequestBundleSignal = SignalProducer<RequestBundle, NoError>

/**
Extracts name and saves it in the request

:param: index Index of row in html
:param: input Input signal

:returns: New signal with name in the request
*/
func extractNames(index: Int)(input: RequestBundleSignal) -> RequestBundleSignal {
    return extractString("document.getElementsByClassName('event-author-wrap mb2')[\(index)].getElementsByTagName('span')[0].innerHTML", input) { (result, bundle, sink) in
        var newRequest = bundle.1
        newRequest.name = result
        sendNext(sink, (bundle.0, newRequest))
        sendCompleted(sink)
    }
}

/**
Extracts title text and saves it in the request

:param: index Index of row in html
:param: input Input signal

:returns: New signal with title text in the request
*/
func extractTitles(index: Int)(input: RequestBundleSignal) -> RequestBundleSignal {
    return extractString("document.getElementsByClassName('event-time mb1 mt0')[\(index)].innerHTML", input) { (result, bundle, sink) in
        var newRequest = bundle.1
        newRequest.title = result
        sendNext(sink, (bundle.0, newRequest))
        sendCompleted(sink)
    }
}

/**
Extracts question text and saves it in the request

:param: index Index of row in html
:param: input Input signal

:returns: New signal with question text in the request
*/
func extractQuestions(index: Int)(input: RequestBundleSignal) -> RequestBundleSignal {
    return extractString("document.getElementsByClassName('event-content pt2 mb2')[\(index)].getElementsByTagName('span')[0].getElementsByTagName('p')[0].innerHTML", input) { (result, bundle, sink) in
        var newRequest = bundle.1
        newRequest.question = result
        sendNext(sink, (bundle.0, newRequest))
        sendCompleted(sink)
    }
}

/**
Runs provided JavaScript and makes the result available to the handler block

:param: javascript  JavaScript to run
:param: inputSignal The source signal
:param: handler     Handler for processing the result from the script

:returns: Returns a signal which emits what's sent to the sink in the `handler`
*/
func extractString(javascript: String, inputSignal: RequestBundleSignal, handler: (String, RequestBundle, SinkOf<Event<RequestBundle, NoError>>) -> ())
     -> RequestBundleSignal {
    return inputSignal |> flatMap(.Merge) { bundle in
        return RequestBundleSignal { sink, disposable in
            let result = bundle.0.stringByEvaluatingJavaScriptFromString(javascript)
            handler(result, bundle, sink)
        }
    }
}
