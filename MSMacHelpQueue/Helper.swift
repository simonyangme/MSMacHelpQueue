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

func extractNames(index: Int)(input: RequestBundleSignal) -> RequestBundleSignal {
    return extractString("document.getElementsByClassName('event-author-wrap mb2')[\(index)].getElementsByTagName('span')[0].innerHTML", input) { (result, bundle, sink) in
        var newRequest = bundle.1
        newRequest.name = result
        sendNext(sink, (bundle.0, newRequest))
        sendCompleted(sink)
    }
}

func extractTitles(index: Int)(input: RequestBundleSignal) -> RequestBundleSignal {
    return extractString("document.getElementsByClassName('event-time mb1 mt0')[\(index)].innerHTML", input) { (result, bundle, sink) in
        var newRequest = bundle.1
        newRequest.title = result
        sendNext(sink, (bundle.0, newRequest))
        sendCompleted(sink)
    }
}

func extractQuestions(index: Int)(input: RequestBundleSignal) -> RequestBundleSignal {
    return extractString("document.getElementsByClassName('event-content pt2 mb2')[\(index)].getElementsByTagName('span')[0].getElementsByTagName('p')[0].innerHTML", input) { (result, bundle, sink) in
        var newRequest = bundle.1
        newRequest.question = result
        sendNext(sink, (bundle.0, newRequest))
        sendCompleted(sink)
    }
}

func extractString(javascript: String, inputSignal: RequestBundleSignal, handler: (String, RequestBundle, SinkOf<Event<RequestBundle, NoError>>) -> ())
     -> RequestBundleSignal {
    return inputSignal |> flatMap(.Merge) { bundle in
        return RequestBundleSignal { sink, disposable in
            let result = bundle.0.stringByEvaluatingJavaScriptFromString(javascript)
            handler(result, bundle, sink)
        }
    }
}
