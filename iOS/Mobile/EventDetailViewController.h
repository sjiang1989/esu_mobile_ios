//
//  EventDetailViewController.h
//  Mobile
//
//  Created by Jason Hocker on 8/7/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import <MessageUI/MessageUI.h>
#import <Accounts/Accounts.h>
#import "UIColor+SchoolCustomization.h"
#import "Module.h"
#import "Event.h"
#import "DetailSelectionDelegate.h"
#import "EventsViewController.h"

@interface EventDetailViewController : UIViewController<EKEventEditViewDelegate,
        UIPopoverControllerDelegate,
        DetailSelectionDelegate,
        UISplitViewControllerDelegate>

@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) EventsViewController *masterController;

@property (strong, nonatomic) NSString *eventTitle;
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *eventDescription;
@property (assign, readwrite) BOOL allDay;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIView *titleBackgroundView;

@property (strong, nonatomic) Module *module;

@property (weak, nonatomic) IBOutlet UILabel *startDateLabelLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabelLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabelLabel;


@property (nonatomic, weak) IBOutlet UINavigationItem *navBarItem;
@property (nonatomic, strong) UIPopoverController *masterPopover;

- (void)dismissMasterPopover;

@end