//
//  LaunchBeacon.swift
//  Mobile
//
//  Created by Bret Hansen on 7/28/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class LaunchBeacon: GoBeacon {
    var moduleKey: String
    var message: String?
    var notification: UILocalNotification?
    
    init(launchBeaconEntity: LaunchBeaconEntity) {
        moduleKey = launchBeaconEntity.moduleKey
        message = launchBeaconEntity.message

        super.init(goBeaconEntity: launchBeaconEntity)
    }

    override var hashValue: Int {
        get {
            return moduleKey.hashValue
        }
    }

    @nonobjc static func ==(lhs: LaunchBeacon, rhs: LaunchBeacon) -> Bool {
        return lhs.moduleKey == rhs.moduleKey
    }

    override var debugDescription: String {
        get {
            var description = "uuid: \(uuid) major: \(major) minor: \(minor) triggerDistance: \(triggerDistance) moduleKey: \(moduleKey)"
            if source != nil {
                description += " source: \(source)"
            }
            if message != nil {
                description += " message: \(message)"
            }
            return description
        }
    }
}
