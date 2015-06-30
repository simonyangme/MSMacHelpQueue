//
//  Request.swift
//  MSMacHelpQueue
//
//  Created by Simon Yang on 6/30/15.
//  Copyright (c) 2015 Simon Yang. All rights reserved.
//

import Foundation

struct Request {
    var name : String?
    var title: String?
    var question: String?
}

extension Request: Equatable {}
func ==(lhs: Request, rhs: Request) -> Bool {
    return lhs.name == rhs.name && lhs.title == rhs.title && lhs.question == rhs.question
}

extension Request: Printable {
    var description: String {
        return "\(name) : \(title)"
    }
}
