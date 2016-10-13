//
//  AuthenticatedRequest.swift
//  Mobile
//
//  Created by Jason Hocker on 5/13/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class AuthenticatedRequest : NSObject {
    
    var url : URL?
    var request : URLRequest?
    var data : Data?
    var response : HTTPURLResponse?
    var error : NSError?

    var dataTask: URLSessionDataTask?
    
    func requestURL(_ url: URL?, fromView viewController: UIViewController?) -> Data? {
        return self.requestURL(url, fromView: viewController, addHTTPHeaderFields: nil)
    }
    
    func requestURL(_ url: URL?, fromView viewController: UIViewController?, addHTTPHeaderFields headers: [String : String]?) -> Data? {
        self.url = url
        self.request = URLRequest(url: self.url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 90)
        if (LoginExecutor.isUsingBasicAuthentication()) {
            self.request?.addAuthenticationHeader()
        }
        if let headers  = headers {
            for (name, headerValue) in headers {
                self.request?.addValue(headerValue, forHTTPHeaderField: name)
                
            }
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .default)
        dataTask = session.dataTask(with: self.request! as URLRequest) {
            data, response, error in
            
            DispatchQueue.main.async() {
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            if let error = error {
                print(error.localizedDescription)
                self.data = nil

            } else if let response = response as? HTTPURLResponse {
                self.data = data
                self.response = response
            }
            semaphore.signal()
        }
        dataTask?.resume()
        let _ = semaphore.wait(timeout: .distantFuture)
        
        //treat redirects from cas just like a log in is needed.  We can't detect which redirects are for cas and which are not.
        if self.error?.code == NSURLErrorUserCancelledAuthentication || self.response?.statusCode == 401 || self.response?.statusCode == 302 {
            CurrentUser.sharedInstance.useFingerprint = false;
            print("AuthenticatedRequest for url: \(url!.absoluteString) errorCode: \(self.error?.code)")
            let user: CurrentUser = CurrentUser.sharedInstance
            user.logoutWithNotification(postNotification: false, requestedByUser: false)
            if let viewController = viewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    LoginExecutor.doLogin(viewController, successCompletionHandler: nil)
                }
            }
        }
        return self.data
    }
}
