//
//  PhotoBrowserViewModel.swift
//  Photomania
//
//  Created by Shane Rogers on 11/9/15.
//  Copyright © 2015 Essan Parto. All rights reserved.
//

import Foundation

class PhotoBrowserViewModel: NSObject {
    var photos = NSMutableOrderedSet()
    let imageCache = NSCache()
    var populatingPhotos = false
    var currentPage = 1
    var indexPaths:[NSIndexPath] = []
    var executeSearch: RACCommand?
    var photoStore = PhotoStore.sharedInstance

    override init() {
        super.init()
        
        executeSearch = RACCommand() {
            (any:AnyObject!) -> RACSignal in
            return self.executeSearchSignal()
        }
    }
    
    private func executeSearchSignal() -> RACSignal {
        populatingPhotos = true
        
        return self.photoStore.getPhotosForPage(currentPage).doNextAs {
            (newPhotos: AnyObject) -> () in
            self.populatingPhotos = false
            self.currentPage++
            
            let currentLastPhotosIndex = self.photos.count
            
            self.photos.addObjectsFromArray(newPhotos as! [PhotoInfo])
            self.indexPaths = (currentLastPhotosIndex ..< self.photos.count).map {NSIndexPath(forItem: $0, inSection: 0)}
            
//            TODO: Add an observer at the view on the viewModel.indexPaths prop which will trigger an collection view insert at the resultant index paths
//            dispatch_async(dispatch_get_main_queue(), {
//                self.collectionView!.insertItemsAtIndexPaths(indexPaths)
//            })
        }
    }
}
