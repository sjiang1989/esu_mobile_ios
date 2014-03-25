//
//  DirectoryViewController.m
//  Mobile
//
//  Created by Jason Hocker on 10/4/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "DirectoryViewController.h"
#import "DirectoryEntry.h"
#import "CurrentUser.h"
#import "Base64.h"
#import "AppDelegate.h"
#import "DirectoryEntryViewController.h"
#import "UIViewController+GoogleAnalyticsTrackerSupport.h"
#import "AppearanceChanger.h"

@interface DirectoryViewController ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) ABPersonSortOrdering sort;
@property (nonatomic, assign) SEL sortSelector;
@property (nonatomic, assign) UILocalizedIndexedCollation *collation;
@property (readwrite, copy, nonatomic) NSArray *tableData;
@property (nonatomic, assign) BOOL firstNameFirst;
@property (nonatomic, strong) NSString *selectedScope;
@end

@implementation DirectoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ABAddressBookRef addressBook;
    addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    __block BOOL accessGranted = NO;
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        //dispatch_release(sema);
    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    if(accessGranted) {
        self.sort = ABPersonGetSortOrdering();
        self.sortSelector = self.sort == kABPersonCompositeNameFormatFirstNameFirst ? @selector(firstName) : @selector(lastName);
    
        self.firstNameFirst = ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst;
        CFRelease(addressBook);
    } else {
        self.sort = kABPersonCompositeNameFormatFirstNameFirst;
        self.sortSelector = @selector(lastName);
        self.firstNameFirst = YES;
    }


    self.title = self.module.name;
    self.tableData = [self partitionObjects:[[NSArray alloc] init] collationStringSelector:self.sortSelector];
    
    if(self.initialScope) {
        self.selectedScope = self.initialScope;
    }
    NSMutableArray *scopes = [[NSMutableArray alloc] init];
    if(self.module && [self.module.type isEqualToString:@"directory"]) {
        if([[self.module propertyForKey:@"student"] isEqualToString:@"true"] && !self.hideStudents) {
            if(!self.selectedScope) self.selectedScope = kDirectoryViewTypeStudent;
            [scopes addObject:kDirectoryViewTypeStudent ];
        }
        if([[self.module propertyForKey:@"faculty"] isEqualToString:@"true"] && !self.hideFaculty) {
            if(!self.selectedScope) self.selectedScope = kDirectoryViewTypeFaculty;
            [scopes addObject:kDirectoryViewTypeFaculty ];
        }
        if([scopes count] > 1) [scopes addObject:kDirectoryViewTypeAll ];
    } else {
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"urls-directory-studentSearch"] && !self.hideStudents) {
            if(!self.selectedScope) self.selectedScope = kDirectoryViewTypeStudent;
            [scopes addObject:kDirectoryViewTypeStudent ];
        }
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"urls-directory-facultySearch"] && !self.hideFaculty ) {
            if(!self.selectedScope) self.selectedScope = kDirectoryViewTypeFaculty;
            [scopes addObject:kDirectoryViewTypeFaculty ];
        }
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"urls-directory-allSearch"] && [scopes count] > 1) {
            if(!self.selectedScope) self.selectedScope = kDirectoryViewTypeAll;
            [scopes addObject:kDirectoryViewTypeAll ];
        }
    }
    
    if([scopes count] > 1) {
        self.searchBar.scopeButtonTitles = [scopes copy];

        if(SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            self.searchBar.tintColor = [UIColor primaryColor];
        }

        if(self.initialScope) {
            self.searchBar.selectedScopeButtonIndex = [self.searchBar.scopeButtonTitles indexOfObject:self.initialScope];
        } else {
            self.searchBar.selectedScopeButtonIndex = 0;
        }
        self.searchBar.showsScopeBar = YES;
        [self.searchBar sizeToFit];
    } else {
        self.searchBar.scopeButtonTitles = nil;
        self.searchBar.showsScopeBar = NO;
        [self.searchBar sizeToFit];
    }
  
    if(self.initialQueryString) {
        self.searchBar.text = self.initialQueryString;
        [self search:self.initialQueryString];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self sendView:@"Directory page" forModuleNamed:self.module.name];
    
    if(!self.initialQueryString) {
        [self.searchBar becomeFirstResponder];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    [self clear];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self search:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (self.data==nil) {
        self.data = [[NSMutableData alloc] initWithCapacity:2048];
    }
    [self.data appendData:incrementalData];
    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
    [self parseResponse:self.data];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.data = nil;
    self.connection = nil;

}

- (void) parseResponse:(NSData *)responseData
{
    NSMutableArray *tempContacts = [[NSMutableArray alloc] init];
    NSError *error;
    if(responseData)
    {
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
        
        //create/update objects
        for(NSDictionary *entry in [json objectForKey:@"entries"]) {
            DirectoryEntry *directoryEntry = [[DirectoryEntry alloc] init];

            if([entry objectForKey:@"personId"] != [NSNull null]) {
                directoryEntry.personId = [entry objectForKey:@"personId"];
            }
            if([entry objectForKey:@"username"] != [NSNull null]) {
                directoryEntry.username = [entry objectForKey:@"username"];
            }
            if([entry objectForKey:@"displayName"] != [NSNull null]) {
                directoryEntry.displayName = [entry objectForKey:@"displayName"];
            }
            if([entry objectForKey:@"firstName"] != [NSNull null]) {
                directoryEntry.firstName = [entry objectForKey:@"firstName"];
            }
            if([entry objectForKey:@"middleName"] != [NSNull null]) {
                directoryEntry.middleName = [entry objectForKey:@"middleName"];
            }
            if([entry objectForKey:@"lastName"] != [NSNull null]) {
                directoryEntry.lastName = [entry objectForKey:@"lastName"];
            }
            if([entry objectForKey:@"title"] != [NSNull null]) {
                directoryEntry.title = [entry objectForKey:@"title"];
            }
            if([entry objectForKey:@"office"] != [NSNull null]) {
                directoryEntry.office = [entry objectForKey:@"office"];
            }
            if([entry objectForKey:@"department"] != [NSNull null]) {
                directoryEntry.department = [entry objectForKey:@"department"];
            }
            if([entry objectForKey:@"phone"] != [NSNull null]) {
                directoryEntry.phone = [entry objectForKey:@"phone"];
            }
            if([entry objectForKey:@"mobile"] != [NSNull null]) {
                directoryEntry.mobile = [entry objectForKey:@"mobile"];
            }
            if([entry objectForKey:@"email"] != [NSNull null]) {
                directoryEntry.email = [entry objectForKey:@"email"];
            }
            if([entry objectForKey:@"street"] != [NSNull null]) {
                directoryEntry.street = [[entry objectForKey:@"street"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            }
            if([entry objectForKey:@"room"] != [NSNull null]) {
                directoryEntry.room = [entry objectForKey:@"room"];
            }
            if([entry objectForKey:@"postOfficeBox"] != [NSNull null]) {
                directoryEntry.postOfficeBox = [entry objectForKey:@"postOfficeBox"];
            }
            if([entry objectForKey:@"city"] != [NSNull null]) {
                directoryEntry.city = [entry objectForKey:@"city"];
            }
            if([entry objectForKey:@"state"] != [NSNull null]) {
                directoryEntry.state = [entry objectForKey:@"state"];
            }
            if([entry objectForKey:@"postalCode"] != [NSNull null]) {
                directoryEntry.postalCode = [entry objectForKey:@"postalCode"];
            }
            if([entry objectForKey:@"country"] != [NSNull null]) {
                directoryEntry.country = [entry objectForKey:@"country"];
            }
            if([entry objectForKey:@"prefix"] != [NSNull null]) {
                directoryEntry.prefix = [entry objectForKey:@"prefix"];
            }
            if([entry objectForKey:@"suffix"] != [NSNull null]) {
                directoryEntry.suffix = [entry objectForKey:@"suffix"];
            }
            [tempContacts addObject:directoryEntry];
        }
    }
    
    if(self.sort == kABPersonSortByFirstName) {
        [tempContacts sortUsingDescriptors:[NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]];
    } else {
        [tempContacts sortUsingDescriptors:[NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]]];
    }

    self.tableData = [self partitionObjects:[tempContacts copy] collationStringSelector:self.sortSelector];
    [self.tableView reloadData];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DirectoryEntry *entry = nil;
    entry = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    static NSString *CellIdentifier = @"Directory Name Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    UILabel *textLabel = (UILabel *)[cell viewWithTag:1];
    textLabel.text = [entry nameOrderedByFirstName:self.firstNameFirst];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DirectoryEntry *entry = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"Show Directory Profile" sender:entry];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self sendEventWithCategory:kAnalyticsCategoryUI_Action withAction:kAnalyticsActionButton_Press withLabel:@"Select directory type" withValue:nil forModuleNamed:self.module.name];
    self.selectedScope = [self.searchBar.scopeButtonTitles objectAtIndex:self.searchBar.selectedScopeButtonIndex];
    if(searchBar.text.length > 0) {
        [self search:searchBar.text];
    }
}

-(void)search:(NSString *)searchString
{
    self.initialQueryString = searchString;
    if([searchString length] > 0) {
        NSString *url = nil;
        NSString *scopeTitle = self.selectedScope;
        if(self.module && [self.module.type isEqualToString:@"directory"]) {
            if([scopeTitle isEqualToString:kDirectoryViewTypeStudent]) {
                url = [self.module propertyForKey:@"studentSearch"];
            } else if([scopeTitle isEqualToString:kDirectoryViewTypeFaculty]) {
                url = [self.module propertyForKey:@"facultySearch"];
            } else {
                 url = [self.module propertyForKey:@"allSearch"];
            }
        } else {
            if([scopeTitle isEqualToString:kDirectoryViewTypeStudent]) {
                url = [[NSUserDefaults standardUserDefaults] objectForKey:@"urls-directory-studentSearch"];
            } else if([scopeTitle isEqualToString:kDirectoryViewTypeFaculty]) {
               url = [[NSUserDefaults standardUserDefaults] objectForKey:@"urls-directory-facultySearch"];
            } else {
               url = [[NSUserDefaults standardUserDefaults] objectForKey:@"urls-directory-allSearch"];
            }
        }
        url = [NSString stringWithFormat:@"%@?searchString=%@", url, [searchString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        CurrentUser *user = [appDelegate currentUser];
        NSMutableString *loginString = (NSMutableString*)[@"" stringByAppendingFormat:@"%@:%@", user.userauth, user.getPassword];

        NSString *encodedLoginData = [Base64 encode:[loginString dataUsingEncoding:NSUTF8StringEncoding]];

        NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginData];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setValue:authHeader forHTTPHeaderField:@"Authorization"];

        NSLog(@"%@",url);
        if(self.connection!=nil){ //cancel if in process
            [self.connection cancel];
        }
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    } else {
        [self clear];
    }
}

-(NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector

{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    
    //put each object into a section
    for (id object in array)
    {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //sort each section
    for (NSMutableArray *section in unsortedSections)
    {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.tableData objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
}

- (NSString *)tableView:(UITableView *)tableView stringForTitleForHeaderInSection:(NSInteger)section
{
    BOOL showSection = [[self.tableData objectAtIndex:section] count] != 0;
    //only show the section title if there are rows in the section
    return (showSection) ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

-(void) clear
{
    self.tableData = [self partitionObjects:[[NSArray alloc] init] collationStringSelector:self.sortSelector];
    [self.tableView reloadData];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([[segue identifier] isEqualToString:@"Show Directory Profile"])
    {
        DirectoryEntryViewController *vc = (DirectoryEntryViewController *)[segue destinationViewController];
        vc.entry = sender;
        vc.module = self.module;
    }
}

@end