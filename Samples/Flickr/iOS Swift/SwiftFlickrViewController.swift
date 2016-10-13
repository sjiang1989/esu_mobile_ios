//
//  SwiftFlickrViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/26/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UIKit


class SwiftFlickrViewController : UIViewController, EllucianMobileLaunchableControllerProtocol {
    
    var module : Module!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateUploadedLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the name of the module that was defined in the cloud as the title of this
        self.title = module.name
        
        //Google analytics
        sendView("flickr sample")
        
        // Set the labels to be the color that was set in the cloud
        descriptionLabel.textColor = UIColor.accent
        dateUploadedLabel.textColor = UIColor.accent
        
        // Show the progess HUD
        let hud = MBProgressHUD.showAdded(to: self.view, animated:true);
        hud.label.text = NSLocalizedString("Loading", comment:"loading message while waiting for data to load")
        
        // After showing the progrss HUD
        
        // Get the API key from the Customizations.plist
        if let api_key = module.property(forKey: "apiKey") {
            
            // Get the user id from the cloud
            if let user_id = module.property(forKey: "userId") {
                
                // Build the flickr URL
                let urlString = "https://api.flickr.com/services/rest/?method=flickr.people.getPublicPhotos&api_key=\(api_key)&per_page=1&format=json&nojsoncallback=1&user_id=\(user_id)&extras=description,date_taken,url_m"
                
                // Download the response from flickr
                let url = URL(string:urlString)
                if let responseData = try? Data(contentsOf: url!) {
                    
                    // Parse the json response
                    do {
                        let jsonObject : Any! = try JSONSerialization.jsonObject(with: responseData)
                        
                        if let jsonDictionary = jsonObject as? NSDictionary {
                            if let photosArray = jsonDictionary["photos"] as? NSDictionary {
                                if let photoArray = photosArray["photo"] as? NSArray {
                                    if let photoDictionary = photoArray[0] as? NSDictionary {
                                        if let url_m = photoDictionary["url_m"] as? String {
                                            if let descriptionDictionary = photoDictionary["description"] as? NSDictionary {
                                                if let description = descriptionDictionary["_content"] as? String {
                                                    if let dateTaken = photoDictionary["datetaken"] as? String {
                                                        // Download the image from flickr asychronously
                                                        imageView.loadImagefromURL(url_m)
                                                        
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
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        // Hide the progress hud
        MBProgressHUD.hide(for: self.view, animated: true);
    }
}
