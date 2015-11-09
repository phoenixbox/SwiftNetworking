//
//  Five100px.swift
//  Photomania
//
//  Created by Essan Parto on 2014-09-25.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

public protocol ResponseCollectionSerializable {
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}

extension Alamofire.Request {
    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: Response<[T], NSError> -> Void) -> Self {
        let responseSerializer = ResponseSerializer<[T], NSError> {
            request, response, data, error in
            guard error == nil else {return .Failure(error!)}
            
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .Success(let value):
                if let response = response {
                    return .Success(T.collection(response: response, representation: value))
                } else {
                    let failureReason = "Response collection could not be serialized"
                    let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

// *** Generic Serializer & response function ***
public protocol ResponseObjectSerializable {
    init?(response: NSHTTPURLResponse, representation: AnyObject)
}
// function conforms to this ResponseObjectSerializable protocol
// taking a completion handler as an argument
extension Alamofire.Request {
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: Response<T,NSError> -> Void) -> Self {
        
        let responseSerializer = ResponseSerializer<T,NSError> {
            request, response, data, error in
            
            guard error == nil else {
                return .Failure(error!)
            }
            
            let JSONResponseSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .Success(let value):
                if let response = response, JSON = T(response: response, representation: value) {
                    return .Success(JSON)
                } else {
                    let failureReason = "JSON could not be serialized into response object \(value)"
                    let error =  Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

// Extend Alamofire.Request with custom serializers
extension Alamofire.Request {
    // *** Response Handler ***
    public func responseImage(completionHandler: Response<UIImage, NSError> -> Void) -> Self {
        // Alamofire's general purpose response handler
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }

    // *** Response Serializer ***
    public static func imageResponseSerializer() -> ResponseSerializer<UIImage, NSError> {
        return ResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .Failure(error!)
            }
            
            guard let validData = data else {
                let failureReason = "Data could not be serialized. Input data was nil"
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            
            guard let image = UIImage(data: validData, scale: UIScreen.mainScreen().scale) else {
                let failureReason = "Data could not be converted to UIImage"
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            return .Success(image)
        }
    }
}

struct Five100px {
  enum Router: URLRequestConvertible {
    static let baseURLString = "https://api.500px.com/v1"
    static let CONSUMER_KEY = "aPJSyqsiWTZVEOevcbh0tSNgRlgdC8Ur07P9XG0y"
    static let CONSUMER_SECRET = "EGrrBzOGTYu4LV0V9JmWlDl0MCPpBBYx4KRMF48V"
    
    case PopularPhotos(Int)
    case PhotoInfo(Int, ImageSize)
    case Comments(Int, Int)
    

   var URLRequest: NSMutableURLRequest {
    let result: (path: String, parameters: [String: AnyObject]) = {
            switch self {
            case .PopularPhotos (let page):
                let params = [
                    "consumer_key": Router.CONSUMER_KEY,
                    "page": "\(page)",
                    "feature": "popular",
                    "rpp": "50",
                    "include_store": "store_download",
                    "include_states": "votes"]
                return ("/photos", params)
            case .PhotoInfo(let photoID, let imageSize):
                let params = [
                    "consumer_key": Router.CONSUMER_KEY,
                    "image_size": "\(imageSize.rawValue)"
                ]
                return ("/photos/\(photoID)", params)
            case .Comments(let photoID, let commentsPage):
                let params = [
                    "consumer_key": Router.CONSUMER_KEY,
                    "comments": "1",
                    "comments_page": "\(commentsPage)"
                ]
                return ("/photos/\(photoID)/comments", params)
            }
        }()
        
        let URL = NSURL(string: Router.baseURLString)
        let URLRequest = NSURLRequest(URL: URL!.URLByAppendingPathComponent(result.path))
        let encoding = Alamofire.ParameterEncoding.URL
        
        return encoding.encode(URLRequest, parameters: result.parameters).0
    }
  }
    
  enum ImageSize: Int {
    case Tiny = 1
    case Small = 2
    case Medium = 3
    case Large = 4
    case XLarge = 5
  }
}

class PhotoInfo: NSObject {
  let id: Int
  let url: String
  
  var name: String?
  
  var favoritesCount: Int?
  var votesCount: Int?
  var commentsCount: Int?
  
  var highest: Float?
  var pulse: Float?
  var views: Int?
  var camera: String?
  var desc: String?
  
  init(id: Int, url: String) {
    self.id = id
    self.url = url
  }
  
  required init(response: NSHTTPURLResponse, representation: AnyObject) {
    // If the serializer was to conform to the SwiftyJSON format then we could do
    // away with this specific value getters. We could use indexes via data["key"]
    self.id = representation.valueForKeyPath("photo.id") as! Int
    self.url = representation.valueForKeyPath("photo.image_url") as! String
    
    self.favoritesCount = representation.valueForKeyPath("photo.favorites_count") as? Int
    self.votesCount = representation.valueForKeyPath("photo.votes_count") as? Int
    self.commentsCount = representation.valueForKeyPath("photo.comments_count") as? Int
    self.highest = representation.valueForKeyPath("photo.highest_rating") as? Float
    self.pulse = representation.valueForKeyPath("photo.rating") as? Float
    self.views = representation.valueForKeyPath("photo.times_viewed") as? Int
    self.camera = representation.valueForKeyPath("photo.camera") as? String
    self.desc = representation.valueForKeyPath("photo.description") as? String
    self.name = representation.valueForKeyPath("photo.name") as? String
  }
  
  override func isEqual(object: AnyObject!) -> Bool {
    return (object as! PhotoInfo).id == self.id
  }
  
  override var hash: Int {
    return (self as PhotoInfo).id
  }
}

final class Comment {
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