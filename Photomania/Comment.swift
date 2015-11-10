//
//  Comment.swift
//  Photomania
//
//  Created by Shane Rogers on 11/10/15.
//  Copyright © 2015 Essan Parto. All rights reserved.
//

import Foundation

final class Comment: ResponseCollectionSerializable {
    static func collection(response response:NSHTTPURLResponse, representation: AnyObject) -> [Comment] {
        var comments = [Comment]()
        for comment in representation.valueForKeyPath("comments") as! [NSDictionary] {
            comments.append(Comment(JSON: comment))
        }
        return comments
    }
    let userFullname: String
    let userPictureURL: String
    let commentBody: String
    
    init(JSON: AnyObject) {
        userFullname = JSON.valueForKeyPath("user.fullname") as! String
        userPictureURL = JSON.valueForKeyPath("user.userpic_url") as! String
        commentBody = JSON.valueForKeyPath("body") as! String
    }
}