//
//  DirectoryEntry.swift
//  Mobile
//
//  Created by Jason Hocker on 12/3/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class DirectoryEntry : NSObject {
    var personId : String?
    var username : String?
    var displayName : String?
    var firstName : String?
    var middleName : String?
    var lastName : String?
    var title : String?
    var office : String?
    var department : String?
    var phone : String?
    var mobile : String?
    var email : String?
    var street : String?
    var room : String?
    var postOfficeBox : String?
    var city : String?
    var state : String?
    var postalCode : String?
    var country : String?
    var prefix : String?
    var suffix : String?
    var imageUrl : String?
    var type : String?
    var nickName : String?
    
    
    func nameToUseForDisplay() -> String {
        if let displayName = self.displayName {
            return displayName
        } else if let firstName = self.firstName, let lastName = self.lastName {
            var components = PersonNameComponents()
            components.givenName = firstName
            components.familyName = lastName
            return PersonNameComponentsFormatter.localizedString(from: components, style: .default)
        } else if let firstName = self.firstName {
            return firstName
        } else if let lastName = self.lastName {
            return lastName
        } else {
            return ""
        }
    }
    
    func nameToUseForFirstNameSort() -> String {
        if let firstName = self.firstName {
            return firstName
        } else if let displayName = self.displayName {
            return displayName
        }
        else {
            return ""
        }
    }
    
    func nameToUseForLastNameSort() -> String {
        if let lastName = self.lastName {
            return lastName
        } else if let displayName = self.displayName {
            return displayName
        }
        else {
            return ""
        }
    }
    
    class func parseResponse(_ responseData : Data) -> [DirectoryEntry] {
        var entries =  [DirectoryEntry]()
        
        let json = JSON(data: responseData)
        //create/update objects
        if json["entries"] != JSON.null {
            for entry in json["entries"].array! {
                let directoryEntry = DirectoryEntry()
                if let personId = entry["personId"].string , personId.characters.count > 0 {
                    directoryEntry.personId = personId
                }
                if let username = entry["username"].string , username.characters.count > 0 {
                    directoryEntry.username = username
                }
                if let displayName = entry["displayName"].string , displayName.characters.count > 0 {
                    directoryEntry.displayName = displayName
                }
                if let firstName = entry["firstName"].string , firstName.characters.count > 0 {
                    directoryEntry.firstName = firstName
                }
                if let middleName = entry["middleName"].string , middleName.characters.count > 0 {
                    directoryEntry.middleName = middleName
                }
                if let lastName = entry["lastName"].string , lastName.characters.count > 0 {
                    directoryEntry.lastName = lastName
                }
                if let nickName = entry["nickName"].string , nickName.characters.count > 0 {
                    directoryEntry.nickName = nickName
                }
                if let title = entry["title"].string , title.characters.count > 0 {
                    directoryEntry.title = title
                }
                if let office = entry["office"].string , office.characters.count > 0 {
                    directoryEntry.office = office
                }
                if let department = entry["department"].string , department.characters.count > 0 {
                    directoryEntry.department = department
                }
                if let phone = entry["phone"].string , phone.characters.count > 0 {
                    directoryEntry.phone = phone
                }
                if let mobile = entry["mobile"].string , mobile.characters.count > 0 {
                    directoryEntry.mobile = mobile
                }
                if let email = entry["email"].string , email.characters.count > 0 {
                    directoryEntry.email = email
                }
                if let street = entry["street"].string , street.characters.count > 0 {
                    directoryEntry.street = street.replacingOccurrences(of: "\\n", with: "\n")
                }
                if let room = entry["room"].string , room.characters.count > 0 {
                    directoryEntry.room = room
                }
                if let postOfficeBox = entry["postOfficeBox"].string , postOfficeBox.characters.count > 0 {
                    directoryEntry.postOfficeBox = postOfficeBox
                }
                if let city = entry["city"].string , city.characters.count > 0 {
                    directoryEntry.city = city
                }
                if let state = entry["state"].string , state.characters.count > 0 {
                    directoryEntry.state = state
                }
                if let postalCode = entry["postalCode"].string , postalCode.characters.count > 0 {
                    directoryEntry.postalCode = postalCode
                }
                if let country = entry["country"].string , country.characters.count > 0 {
                    directoryEntry.country = country
                }
                if let prefix = entry["prefix"].string , prefix.characters.count > 0 {
                    directoryEntry.prefix = prefix
                }
                if let suffix = entry["suffix"].string , suffix.characters.count > 0 {
                    directoryEntry.suffix = suffix
                }
                if let type = entry["type"].string , type.characters.count > 0 {
                    directoryEntry.type = type
                }
                if let imageUrl = entry["imageUrl"].string , imageUrl.characters.count > 0 {
                    directoryEntry.imageUrl = imageUrl
                }
                entries.append(directoryEntry)
            }
        }
        return entries
    }
}
