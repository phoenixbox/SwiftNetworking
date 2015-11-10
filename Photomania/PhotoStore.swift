//
//  PhotoStore.swift
//  Photomania
//
//  Created by Shane Rogers on 11/10/15.
//  Copyright © 2015 Essan Parto. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Dollar
import Cent

class PhotoStore: NSObject {
    static let sharedInstance = PhotoStore()
    
    //MARK: Properties
    
    private let requests: NSMutableSet
    
    //MARK: Public API
    
    override init() {
        requests = NSMutableSet()
    }
    
    func getPhotosForPage(currentPage: Int) -> RACSignal {
        return RACSignal.createSignal({
            (subscriber: RACSubscriber!) -> RACDisposable! in
                let request = Alamofire.request(Five100px.Router.PopularPhotos(currentPage)).responseJSON {
                    response in
                    if (response.result.error == nil) {
                        let json = JSON(data: response.data!)
                        //  Operate on JSON - then return JSON
                        let filtered = $.chain(json["photos"].array!)
                            .filter { $0["nsfw"].bool! == false }
                            .map { return ["id": $1["id"].int!, "image_url": $1["image_url"].string!]}
                            .value
                        // Operate on the JSON
                        let newPhotos = filtered.map { (blob: JSON) -> PhotoInfo in
                            return PhotoInfo(id: blob["id"].int!, url: blob["image_url"].string!)
                        }
                        
                        subscriber.sendNext(newPhotos)
                        subscriber.sendCompleted()
                    } else {
                        print("Request Error \(response.result.error?.localizedDescription)")
                        subscriber.sendError(response.result.error)
                    }
                }
            
                self.requests.addObject(request)
            
                return RACDisposable(block: {
                    self.requests.removeObject(request)
                })
        })
    }
}