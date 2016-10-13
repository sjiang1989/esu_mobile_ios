//
//  DirectoryEntryViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 12/7/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI
import Contacts
import ContactsUI
import MapKit

class DirectoryEntryViewController : UITableViewController, CNContactViewControllerDelegate {
    
    var entry : DirectoryEntry?
    var module : Module?
    @IBOutlet var headingWithoutImageCell: UITableViewCell!
    @IBOutlet var headingWithImageCell: UITableViewCell!
    @IBOutlet var emailCell: UITableViewCell!
    @IBOutlet var mobileCell: UITableViewCell!
    @IBOutlet var phoneCell: UITableViewCell!
    @IBOutlet var officeCell: UITableViewCell!
    @IBOutlet var roomCell: UITableViewCell!
    @IBOutlet var addressCell: UITableViewCell!
    
    @IBOutlet var nameInHeaderWithoutImageCellLabel: UILabel!
    @IBOutlet var nameInHeaderWithImageCellLabel: UILabel!
    @IBOutlet var titleInHeaderWithoutImageCellLabel: UILabel!
    @IBOutlet var titleInHeaderWithImageCellLabel: UILabel!
    @IBOutlet var departmentInHeaderWithoutImageCellLabel: UILabel!
    @IBOutlet var departmentInHeaderWithImageCellLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var mobileLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var moreInfoInHeaderWithoutImageCellButton: UIButton!
    @IBOutlet weak var moreInfoInHeaderWithImageCellButton: UIButton!
    
    @IBOutlet var officeLabel: UILabel!
    @IBOutlet var roomLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    
    @IBOutlet var emailIconImageView: UIImageView!
    @IBOutlet var mobileButton: UIButton!
    @IBOutlet var mobileIconImageView: UIImageView!
    @IBOutlet var phoneIconImageView: UIImageView!
    @IBOutlet var addressIconImageView: UIImageView!
    
    @IBOutlet var leftConstraint: NSLayoutConstraint!
    
    var cellsToShow = [UITableViewCell]()
    
    override func viewDidLoad() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 160.0
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        populateCells()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("Directory card", moduleName: self.module?.name)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellsToShow[(indexPath as NSIndexPath).row]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellsToShow.count
    }
    
    func populateCells() {
        if let entry = entry {
            if entry.imageUrl != nil {
                cellsToShow.append(headingWithImageCell)
                nameInHeaderWithImageCellLabel.text = name()
                titleInHeaderWithImageCellLabel.text = entry.title
                leftConstraint.constant = 68
                departmentInHeaderWithImageCellLabel.text = entry.department
                if let logo = entry.imageUrl , logo != "" {
                    imageView.loadImagefromURL(logo, successHandler: {  self.imageView.convertToCircleImage() }, failureHandler:  { self.imageView.isHidden = true
                        DispatchQueue.main.async {
                            () -> Void in
                            self.leftConstraint.constant = 0
                            self.view.setNeedsLayout()
                        }
                    })
                }
                if CurrentUser.sharedInstance.isLoggedIn {
                    moreInfoInHeaderWithImageCellButton.isHidden = true
                } else {
                    moreInfoInHeaderWithImageCellButton.tintColor = UIColor.primary
                }
                
            } else {
                cellsToShow.append(headingWithoutImageCell)
                nameInHeaderWithoutImageCellLabel.text = name()
                titleInHeaderWithoutImageCellLabel.text = entry.title
                departmentInHeaderWithoutImageCellLabel.text = entry.department
                if CurrentUser.sharedInstance.isLoggedIn {
                    moreInfoInHeaderWithoutImageCellButton.isHidden = true
                } else {
                    moreInfoInHeaderWithoutImageCellButton.tintColor = UIColor.primary
                }
            }

            if let email = entry.email , email.characters.count > 0 {
                cellsToShow.append(emailCell)
                emailLabel.text = email
                emailIconImageView.image = emailIconImageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                emailIconImageView.tintColor = UIColor.primary
            }
            if let mobile = entry.mobile , mobile.characters.count > 0 {
                cellsToShow.append(mobileCell)
                mobileLabel.text = mobile
                mobileIconImageView.image = mobileIconImageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                mobileIconImageView.tintColor = UIColor.primary

                let image = UIImage(named: "sms-icon")
      
                mobileButton.setImage(image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: UIControlState())
                mobileButton.tintColor = UIColor.primary
            }
            if let phone = entry.phone , phone.characters.count > 0 {
                cellsToShow.append(phoneCell)
                phoneLabel.text = phone
                phoneIconImageView.image = phoneIconImageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                phoneIconImageView.tintColor = UIColor.primary
            }
            if let office = entry.office , office.characters.count > 0 {
                cellsToShow.append(officeCell)
                officeLabel.text = office
            }
            if let room = entry.room , room.characters.count > 0 {
                cellsToShow.append(roomCell)
                roomLabel.text = room
            }
            if let address = address() , address.characters.count > 0 {
                cellsToShow.append(addressCell)
                addressLabel.text = address
                addressIconImageView.image = addressIconImageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                addressIconImageView.tintColor = UIColor.primary
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func name() -> String {
        if let displayName = entry?.displayName , displayName.characters.count > 0 {
            return displayName
        } else {
            if let entry = entry {
                
                var components = PersonNameComponents()
                components.namePrefix = entry.prefix
                components.givenName = entry.firstName
                components.middleName = entry.middleName
                components.familyName = entry.lastName
                components.nickname = entry.nickName
                components.nameSuffix = entry.suffix
                return PersonNameComponentsFormatter.localizedString(from: components, style: .long)
            } else {
                return ""
            }
        }
    }
    
    func address() -> String? {
        var address : String? = nil
        var csp : String? = nil
        var street : String? = nil
        
        if let entry = self.entry {
            if let city = entry.city, let state = entry.state, let postalCode = entry.postalCode , city.characters.count > 0 &&
                state.characters.count > 0 && postalCode.characters.count > 0 {
                    csp = "\(city), \(state) \(postalCode)"
            }
            else if let city = entry.city, let state = entry.state , city.characters.count > 0 &&
                state.characters.count > 0 {
                    csp = "\(city), \(state)"
            }
            else if let city = entry.city, let postalCode = entry.postalCode , city.characters.count > 0 && postalCode.characters.count > 0 {
                csp = "\(city), \(postalCode)"
            }
            else if let state = entry.state, let postalCode = entry.postalCode , state.characters.count > 0 && postalCode.characters.count > 0 {
                csp = "\(state) \(postalCode)"
            }
            else if let city = entry.city {
                csp = city
            }
            else if let state = entry.state {
                csp = state
            }
            else if let postalCode = entry.postalCode {
                csp = postalCode
            }
            
            if let eStreet = entry.street, let postOfficeCode = entry.postOfficeBox , eStreet.characters.count > 0 && postOfficeCode.characters.count > 0 {
                street = "\(postOfficeCode)\n\(eStreet)"
            } else if let eStreet = entry.street , eStreet.characters.count > 0 {
                street = eStreet
            } else if let postOfficeCode = entry.postOfficeBox , postOfficeCode.characters.count > 0 {
                street = "\(postOfficeCode)"
            }
            
            if let street = street, let csp = csp, let country = entry.country , street.characters.count > 0 && country.characters.count > 0 {
                address = "\(street)\n\(csp)\n\(country)"
            }
            else if let street = street, let csp = csp , street.characters.count > 0 {
                address = "\(street)\n\(csp)"
            }
            else if let street = street, let country = entry.country , street.characters.count > 0 && country.characters.count > 0 {
                address = "\(street)\n\(country)"
            }
            else if let csp = csp, let country = entry.country {
                address = "\(csp)\n\(country)"
            }
            else if let street = entry.street , street.characters.count > 0 {
                
                address = street
            }
            else if let csp = csp {
                address = csp
            }
            else if let postalCode = entry.postalCode , postalCode.characters.count > 0 {
                address = postalCode
            }
        }
        return address
        
        
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell == emailCell {
            if let email = self.entry?.email {
                self.sendEventToTracker1(category: .ui_Action, action: .invoke_Native, label: "Send e-mail", moduleName: self.module?.name)
                UIApplication.shared.openURL(URL(string: "mailto://\(email)")!)
            }
            
        } else if cell == mobileCell {
            self.sendEventToTracker1(category: .ui_Action, action: .invoke_Native, label: "Call Phone Number", moduleName: self.module?.name)
            let phone = self.entry?.mobile?.components(separatedBy: CharacterSet(charactersIn: "() -")).joined(separator: "")
            if let phone = phone {
                UIApplication.shared.openURL(URL(string: "tel://\(phone)")!)
            }
            
        } else if cell == phoneCell {
            self.sendEventToTracker1(category: .ui_Action, action: .invoke_Native, label: "Call Phone Number", moduleName: self.module?.name)
            let phone = self.entry?.phone?.components(separatedBy: CharacterSet(charactersIn: "() -")).joined(separator: "")
            if let phone = phone {
                UIApplication.shared.openURL(URL(string: "tel://\(phone)")!)
            }
        } else if cell == addressCell {
            self.sendEventToTracker1(category: .ui_Action, action: .invoke_Native, label: "Open Maps", moduleName: self.module?.name)
            if let address = address() {
                
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
                    if((error) != nil){
                        print("Error", error)
                    }
                    if let placemark = placemarks?.first {
                        let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                        let placeMark: MKPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                        let mapItem: MKMapItem = MKMapItem(placemark: placeMark)
                        mapItem.name = self.name()
                        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        mapItem.openInMaps(launchOptions: options)

                    }
                })
            }
        }
    }
    
    @IBAction func sendText(_ sender: AnyObject) {
        self.sendEventToTracker1(category: .ui_Action, action: .invoke_Native, label: "Text Phone Number", moduleName: self.module?.name)
        let phone = self.entry?.mobile?.components(separatedBy: CharacterSet(charactersIn: "() -")).joined(separator: "")
        if let phone = phone {
            UIApplication.shared.openURL(URL(string: "sms:\(phone)")!)
        }
    }
    
    @IBAction func addToAddressBook(_ sender: AnyObject) {
        self.sendEventToTracker1(category: .ui_Action, action: .invoke_Native, label: "Add contact", moduleName: self.module?.name)
        
        let store = CNContactStore()
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        // Update our UI if the user has granted access to their Contacts
        case .authorized:
            self.accessGrantedForContacts()
            
        // Prompt the user for access to Contacts if there is no definitive answer
        case .notDetermined :
            store.requestAccess(for: .contacts) {granted, error in
                if granted {
                    DispatchQueue.main.async {
                        self.accessGrantedForContacts()
                        return
                    }
                }
            }
        case .denied, .restricted:
            accessDeniedForContacts()
        }
        
    }

    
    func accessDeniedForContacts() {
        let alert = UIAlertController(title: NSLocalizedString("Unable to access contacts", comment: "unable to access contacts alert view title"), message: NSLocalizedString("Unable to access contacts. Go to Settings to grant permission to Ellucian GO", comment: "unable to access contacts alert view message. Settings application is part of iOS.  Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: {
            _ in
            let url = URL(string:UIApplicationOpenSettingsURLString)!
            UIApplication.shared.openURL(url)
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    @available(iOS 9, *)
    func accessGrantedForContacts() {
        let contact = CNMutableContact()
        if let entry = self.entry {
            
            if let firstName = entry.firstName {
                contact.givenName = firstName
            }
            if let middleName = entry.middleName {
                contact.middleName = middleName
            }
            if let lastName = entry.lastName {
                contact.familyName = lastName
            }
            if let nickName = entry.nickName {
                contact.nickname = nickName
            }
            if let office = entry.office {
                contact.organizationName = office
            }
            if let title = entry.title {
                contact.jobTitle = title
            }
            if let department = entry.department {
                contact.departmentName = department
            }
            
            if let prefix = entry.prefix {
                contact.namePrefix = prefix
            }
            if let suffix = entry.suffix {
                contact.nameSuffix = suffix
            }
            
            var phoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
            if let mobile = entry.mobile {
                let mobileLabeledValue = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: mobile))
                phoneNumbers.append(mobileLabeledValue)
            }
            if let phone = entry.phone {
                let phoneLabeledValue = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))
                phoneNumbers.append(phoneLabeledValue)
            }
            contact.phoneNumbers = phoneNumbers
            
            var emails = [CNLabeledValue<NSString>]()
            if let email = entry.email {
                let emailLabeledValue = CNLabeledValue(label: CNLabelOther, value: email as NSString)
                emails.append(emailLabeledValue)
            }
            contact.emailAddresses = emails

            let address = CNMutablePostalAddress()
            
            if let street = entry.street {
                address.street = street
            }
            
            if let city = entry.city {
                address.city = city
            }
            
            if let state = entry.state {
                address.state = state
            }
            
            if let postalCode = entry.postalCode {
                address.postalCode = postalCode
            }
            
            if let country = entry.country {
                address.country = country
            }
            
            contact.postalAddresses = [CNLabeledValue(label: CNLabelOther,
                value: address)]

            if let image = imageView.image {
                contact.imageData = UIImagePNGRepresentation(image)
            }

            let ucvc = CNContactViewController(forUnknownContact: contact)
            ucvc.delegate = self
            ucvc.allowsEditing = true
            ucvc.allowsActions = true
            ucvc.alternateName = name()
            ucvc.contactStore = CNContactStore()

            self.navigationController?.pushViewController(ucvc, animated: true)
        }
        
    }
    
    @IBAction func alertSignIn(_ sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("More contact information may be displayed if you are signed in.", comment: "Message in directory suggesting to sign in for more information"), preferredStyle: .alert)

        let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { (action) in
            
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
