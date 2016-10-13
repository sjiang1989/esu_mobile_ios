//
//  NotificationRegistration.m
//  Mobile
//
//  Created by Bret Hansen  on 1/14/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "NotificationManager.h"
#import "Ellucian_GO-Swift.h"

@implementation NotificationManager

+(void) registerDeviceIfNeeded
{
    NSUserDefaults* defaults = [AppGroupUtilities userDefaults];
    NSString* notificationRegistrationUrl = [defaults stringForKey:@"notification-registration-url"];
    
    CurrentUser *user = [CurrentUser sharedInstance];
    
    // if notification url is defined and user is logged in
    if (user && [user isLoggedIn] && notificationRegistrationUrl) {
        
        UIUserNotificationSettings* notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (notificationSettings != nil) {
            // make sure it has the types we want for remote notifications
            if (!([notificationSettings types] & (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound))) {
                NSSet<UIUserNotificationCategory *>* categories = [notificationSettings categories];
                notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:categories];
                [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
            }
        } else {
            notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        }
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

+(void) registerDeviceToken:(NSData*)deviceToken
{
    NSUserDefaults* defaults = [AppGroupUtilities userDefaults];
    
    NSString* notificationRegistrationUrl = [defaults stringForKey:@"notification-registration-url"];
    NSString* notificationEnabled = [defaults stringForKey:@"notification-enabled"];

    CurrentUser *user = [CurrentUser sharedInstance];
    
    NSString* deviceTokenString = [[[NSString stringWithFormat:@"%@", deviceToken] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString* applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    
    // if urlString is set and either notificationEnabled hasn't been determined or is YES, then attempt to register
    if (notificationRegistrationUrl && (!notificationEnabled || [notificationEnabled boolValue] )) {
        NSMutableDictionary* registerDictionary =
            [
               @{
                   @"devicePushId": deviceTokenString,
                   @"platform": @"ios",
                   @"applicationName": applicationName,
                   @"loginId": user.userauth,
                   @"sisId": user.userid
               } mutableCopy ];
        if (user.email) {
            [registerDictionary setValue: user.email forKey:@"email"];
        }
        
        NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:notificationRegistrationUrl]];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSString *authenticationMode = [defaults objectForKey:@"login-authenticationType"];
        if(!authenticationMode || [authenticationMode isEqualToString:@"native"]) {
            [urlRequest addAuthenticationHeader];
        }
        
        [urlRequest setHTTPMethod:@"POST"];

        NSError *jsonError;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:registerDictionary options:(NSJSONWritingOptions)NULL error:&jsonError];
        [urlRequest setHTTPBody:jsonData];

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        NSURLSession *session = [NSURLSession sharedSession]; // or create your own session with your own NSURLSessionConfiguration
        NSURLSessionTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {

            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            NSInteger statusCode = [httpResponse statusCode];
            
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            // check if the status is "success" if not we should not continue to attempt to interact with the Notifications API
            if (statusCode != 200 && statusCode != 201) {
                NSLog(@"Device token registration failed status: %li - %@", (long) (long)statusCode, [error localizedDescription]);
            } else {
                NSString* status = [jsonResponse objectForKey:@"status"] ? : @"disabled";
                BOOL enabled = [status isEqualToString:@"success"];
                NSString* notificationEnabled = enabled ? @"YES" : @"NO";
                [defaults setObject:notificationEnabled forKey:@"notification-enabled"];
                
                if (enabled) {
                    // remember the registered user, so we re-register if user id changes
                    [defaults setObject:[user userid] forKey:@"registered-user-id"];
                }
            }
            
            dispatch_semaphore_signal(semaphore);

        }];
        [task resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    }
}

@end
