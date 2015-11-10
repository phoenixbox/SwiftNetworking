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
//    var photos = NSMutableOrderedSet()
//    let imageCache = NSCache()
    let refreshControl = UIRefreshControl()
    var populatingPhotos = false
    var currentPage = 1
  
    let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
    
    // ****
    var viewModel:PhotoBrowserViewModel = PhotoBrowserViewModel()

  // MARK: Life-cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupView()
    bindViewModel()
    populatePhotos()
  }
    
    func bindViewModel() {
        RACObserve(viewModel, keyPath: "photos").subscribeNext {
            (d:AnyObject!) -> () in
            print("*** Photos changed!! ***")
            self.collectionView!.reloadData()
        }
    }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: CollectionView
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewModel.photos.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
    
    let imageURL = (self.viewModel.photos.objectAtIndex(indexPath.row) as! PhotoInfo).url
    
    cell.imageView.image = nil
    cell.request?.cancel()
    
    if let image = self.viewModel.imageCache.objectForKey(imageURL) as? UIImage {
        cell.imageView.image = image
    } else {
        cell.request = Alamofire.request(.GET, imageURL).validate(contentType: ["image/*"]).responseImage() {
            response in
            
            if let img = response.result.value where response.result.error == nil {
                self.viewModel.imageCache.setObject(img, forKey: response.request!.URLString)
                cell.imageView.image = img
            }
        }
    }

    // Use the custom responseImage response handler
    
//    sd web image implmentation
//    
//    cell.imageView.sd_setImageWithURL(NSURL(string: imageURL))
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) 
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("ShowPhoto", sender: (self.viewModel.photos.objectAtIndex(indexPath.item) as! PhotoInfo).id)
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
    
    // prepare for Segue is the point at which model attrs can be sent to the destination view controller
    // use as the glue for ViewModel initialization
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
        if (viewModel.populatingPhotos) {
            return
        }
        viewModel.populatingPhotos = true
        // Trigger the search
        viewModel.executeSearch?.execute(nil).subscribeNext {
            (d:AnyObject!) -> () in
            let count = self.viewModel.photos.count
            print("*** Search Execution Finished!! photoCount: \(count) ***")
            self.collectionView!.reloadData()
        }
        
        // 2.Perform request
        // PhotoBrowserViewModel - PhotoBrowserImpl would handle the request
    }
    
  func handleRefresh() {
    refreshControl.beginRefreshing()
    
    self.viewModel.photos.removeAllObjects()
    self.viewModel.currentPage = 1
    self.collectionView!.reloadData()
    
    refreshControl.endRefreshing()
    populatePhotos()
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
