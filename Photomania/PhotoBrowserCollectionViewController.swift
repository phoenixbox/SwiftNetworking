//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Dollar
import Cent
import SDWebImage

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  var photos = NSMutableOrderedSet()
  
  let refreshControl = UIRefreshControl()
    var populatingPhotos = false
    var currentPage = 1
  
  let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
  let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
  
  // MARK: Life-cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupView()
    
    self.populatePhotos()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: CollectionView
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
    
    let imageURL = (photos.objectAtIndex(indexPath.row) as! PhotoInfo).url
    
    cell.imageView.image = nil
    cell.request?.cancel()

    // Use the custom responseImage response handler
    cell.request = Alamofire.request(.GET, imageURL).validate(contentType: ["image/*"]).responseImage() {
        response in
        
        if let img = response.result.value where response.result.error == nil {
            cell.imageView.image = img
        }
    }
//    sd web image implmentation
//    
//    cell.imageView.sd_setImageWithURL(NSURL(string: imageURL))
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) 
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("ShowPhoto", sender: (self.photos.objectAtIndex(indexPath.item) as! PhotoInfo).id)
  }
  
  // MARK: Helper
  
  func setupView() {
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    let layout = UICollectionViewFlowLayout()
    let itemWidth = (view.bounds.size.width - 2) / 3
    layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    layout.minimumInteritemSpacing = 1.0
    layout.minimumLineSpacing = 1.0
    layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
    
    collectionView!.collectionViewLayout = layout
    
    navigationItem.title = "Featured"
    
    collectionView!.registerClass(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
    collectionView!.registerClass(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
    
    refreshControl.tintColor = UIColor.whiteColor()
    refreshControl.addTarget(self, action: "handleRefresh", forControlEvents: .ValueChanged)
    collectionView!.addSubview(refreshControl)
  }
    
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowPhoto" {
      (segue.destinationViewController as! PhotoViewerViewController).photoID = sender!.integerValue
      (segue.destinationViewController as! PhotoViewerViewController).hidesBottomBarWhenPushed = true
    }
  }
    // 1
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
            populatePhotos()
        }
    }
    
    func populatePhotos() {
        // 1.Control duplicate requests
        if (populatingPhotos) {
            return
        }
        populatingPhotos = true
        
        // 2.Perform request
        Alamofire.request(Five100px.Router.PopularPhotos(self.currentPage)).responseJSON {
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
                let currentLastPhotoIndex = self.photos.count
                
                self.photos.addObjectsFromArray(newPhotos)
                // Use of ..< half-closed range operator - a up to be not including b
                // Same as closed range -1
                let indexPaths = (currentLastPhotoIndex ..< self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                })
                
                self.currentPage++
            } else {
                print("Request Error \(response.result.error?.localizedDescription)")
            }

            self.populatingPhotos = false
        }
    }
  func handleRefresh() {
    
  }
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
  let imageView = UIImageView()
  var request: Alamofire.Request?
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor(white: 0.1, alpha: 1.0)
    
    imageView.frame = bounds
    addSubview(imageView)
  }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
  let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    spinner.startAnimating()
    spinner.center = self.center
    addSubview(spinner)
  }
}
