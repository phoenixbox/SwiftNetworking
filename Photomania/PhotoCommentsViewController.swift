//
//  PhotoCommentsViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-25.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoCommentsViewController: UITableViewController {
  var photoID: Int = 0
  var comments: [Comment]?
  
  // MARK: Life-Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 50.0
    
    title = "Comments"
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .Done, target: self, action: "dismiss")
    
    // Params of photoId and comments page offset
    // Make response generic of array type Comment
    Alamofire.request(Five100px.Router.Comments(photoID, 1)).validate().responseCollection() {
        (response: Response<[Comment], NSError>) in
        
        if let error = response.result.error {
            print(error.localizedDescription)
        } else {
            switch response.result {
            case .Success(let comments):
                self.comments = comments
                self.tableView.reloadData()
                
            case .Failure(let error):
                print(error.localizedDescription)
            }
        }
    }
  }
  
  func dismiss() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  // MARK: - TableView
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return comments?.count ?? 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! PhotoCommentTableViewCell
    cell.userFullnameLabel.text = self.comments?[indexPath.row].userFullname
    cell.commentLabel.text = self.comments?[indexPath.row].commentBody
    
    // Null out the existing image
    cell.userImageView.image = nil
    if let pictureURL = self.comments?[indexPath.row].userPictureURL {
        Alamofire.request(.GET, pictureURL).validate().responseImage() {
            response in
            if let img = response.result.value {
                cell.imageView!.image = img
            }
        }
    }
    
    
    return cell
  }
}

class PhotoCommentTableViewCell: UITableViewCell {
  @IBOutlet weak var userImageView: UIImageView!
  @IBOutlet weak var commentLabel: UILabel!
  @IBOutlet weak var userFullnameLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    userImageView.layer.cornerRadius = 5.0
    userImageView.layer.masksToBounds = true
    
    commentLabel.numberOfLines = 0
  }
}