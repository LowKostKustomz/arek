//
//  ArekNotifications.swift
//  arek
//
//  Copyright (c) 2016 Ennio Masi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

import UIKit
import UserNotifications

open class ArekNotifications: ArekBasePermission, ArekPermissionProtocol {
    
    public enum ArekNotificationType {
        case alert
        case badge
        case sound
        case carPlay
        
        @available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use unAuthorizationOption")
        var uiUserNotificationType: UIUserNotificationType? {
            switch self {
            case .alert:
                return .alert
            case .badge:
                return .badge
            case .sound:
                return .sound
            case .carPlay:
                return nil
            }
        }
        
        @available(iOS 10.0, *)
        var unAuthorizationOption: UNAuthorizationOptions {
            switch self {
            case .alert:
                return .alert
            case .badge:
                return .badge
            case .sound:
                return .sound
            case .carPlay:
                return .carPlay
            }
        }
    }
    
    open var identifier: String = "ArekNotifications"
    open var notificationTypes: [ArekNotificationType] = [.alert, .badge, .sound, .carPlay]

    open func status(completion: @escaping ArekPermissionResponse) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                switch settings.authorizationStatus {
                case .notDetermined:
                    return completion(.notDetermined)
                case .denied:
                    return completion(.denied)
                case .authorized,
                     .provisional:
                    return completion(.authorized)
                }
            }
        } else if #available(iOS 9.0, *) {
            if let types = UIApplication.shared.currentUserNotificationSettings?.types {
                if types.isEmpty {
                    return completion(.notDetermined)
                }
            }

            return completion(.authorized)
        }
    }

    open func askForPermission(completion: @escaping ArekPermissionResponse) {
        if #available(iOS 10.0, *) {
            let options: UNAuthorizationOptions = self
                .notificationTypes
                .compactMap { $0.unAuthorizationOption }
                .reduce(UNAuthorizationOptions(), { (result, option) -> UNAuthorizationOptions in
                    var options = result
                    options.insert(option)
                    return options
            })
            UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
                if error != nil {
                    return completion(.notDetermined)
                }
                if granted {
                    self.registerForRemoteNotifications()
                    
                    return completion(.authorized)
                }
                return completion(.denied)
            }
        } else if #available(iOS 9.0, *) {
            let types = self
                .notificationTypes
                .compactMap { $0.uiUserNotificationType }
                .reduce(UIUserNotificationType(), { (result, type) -> UIUserNotificationType in
                    var types = result
                    types.insert(type)
                    return types
                })
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: types, categories: nil))
            self.registerForRemoteNotifications()
        }
    }
    
    fileprivate func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
