//
//  SwiftFlickrViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/26/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UIKit


class SwiftFlickrViewController : UIViewController {
    
    var module : Module!

    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateUploadedLabel: UILabel!
    @IBOutlet weak var imageView: AsynchronousImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Use the name of the module that was defined in the cloud as the title of this
        self.title = module.name;

        // Set the labels to be the color that was set in the cloud
        descriptionLabel.textColor = UIColor.accentColor();
        dateUploadedLabel.textColor = UIColor.accentColor();
        
        // Show the progess HUD
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated:true);
        hud.labelText = NSLocalizedString("Loading", comment:"loading message while waiting for data to load");
        
        // After showing the progrss HUD
        
        // Get the API key from the Customizations.plist
        var api_key = module.propertyForKey("apiKey");
        
        // Get the user id from the cloud
        var user_id = module.propertyForKey("userId");
        
        // Build the flickr URL
        var urlString = "https://api.flickr.com/services/rest/?method=flickr.people.getPublicPhotos&api_key=\(api_key)&per_page=1&format=json&nojsoncallback=1&user_id=\(user_id)&extras=description,date_taken,url_m";
        
        // Download the response from flickr
        var error: NSError?
        var url = NSURL(string:urlString)
        var responseData = NSData(contentsOfURL:url)

        // Parse the json response
        var jsonObject : AnyObject! = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: nil)
        
        if var jsonDictionary = jsonObject as? NSDictionary {
            if var photosArray = jsonDictionary["photos"] as? NSDictionary {
                if var photoArray = photosArray["photo"] as? NSArray {
                    if var photoDictionary = photoArray[0] as? NSDictionary {
                        if var url_m = photoDictionary["url_m"] as? String {
                            if var descriptionDictionary = photoDictionary["description"] as? NSDictionary {
                                if var description = descriptionDictionary["_content"] as? String {
                                    if var dateTaken = photoDictionary["datetaken"] as? String {
                                        // Download the image from flickr asychronously
                                        imageView.loadImageFromURLString(url_m);
                                        
                                        // Set the text in the labels
                                        descriptionLabel.text = description;
                                        dateUploadedLabel.text = dateTaken;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Hide the progress hud
        MBProgressHUD.hideHUDForView(self.view, animated: true);      
    }
}