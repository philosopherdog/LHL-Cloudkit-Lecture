//
//  AppDelegate.swift
//  CloudKitDemo
//
//  Created by steve on 2018-03-09.
//  Copyright © 2018 steve. All rights reserved.
//

import UIKit
import CloudKit

enum R {
  static let Person = "Person"
  static let firstName = "firstName"
  static let lastName = "lastName"
  static let age = "age"
  static let subscriptionID = "person-changes"
  static let subscriptionWasCreated = "subscriptionWasCreated"
  
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  let container = CKContainer.default()
  var db: CKDatabase!
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    db = container.publicCloudDatabase
    //    create()
    //    read { (_) in}
    //    update()
    //    delete()
    application.registerForRemoteNotifications()
    setupSubscription()
    return true
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
    if notification.subscriptionID == R.subscriptionID {
      // kick off a fetch
      print(#line, userInfo)
      completionHandler(UIBackgroundFetchResult.newData)
    }
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print(#line, "registered")
    
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(#line, error.localizedDescription)
  }
  
}

// CRUD

extension AppDelegate {
  func create() {
    let record = CKRecord(recordType: R.Person)
    record[R.firstName] = "Lisa" as NSString
    record[R.lastName] = "Lent" as NSString
    record[R.age] = 22 as NSNumber
    let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
    operation.perRecordCompletionBlock = { record, error in
      guard error == nil else {
        print(#line, error!.localizedDescription)
        return
      }
      print(#line, record)
    }
    operation.modifyRecordsCompletionBlock = {records, _, error in
      guard error == nil else {
        print(#line, error!.localizedDescription)
        return
      }
      guard let records = records else {
        return
      }
      print(#line, records)
    }
    db.add(operation)
  }
  
  func read(completion: @escaping (CKRecord)-> () )  {
    let predicate = NSPredicate(format:"firstName = 'Lisa'")
    let query = CKQuery(recordType: R.Person, predicate: predicate)
    let operation = CKQueryOperation(query: query)
    operation.recordFetchedBlock = { record in
      print(#line, record)
      completion(record)
    }
    operation.queryCompletionBlock = { cursor, error in
      guard error == nil else {
        print(#line, error!.localizedDescription)
        return
      }
      print(#line, cursor ?? "cursor is nil")
    }
    db.add(operation)
  }
  
  func update() {
    read { (record) in
      guard let age = record[R.age] as? NSNumber else {  return }
      record[R.age] = age.intValue + 1 as NSNumber
      let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
      operation.perRecordCompletionBlock = { record, error in
        guard error == nil else {
          print(#line, error!.localizedDescription)
          return
        }
        print(#line, record)
      }
      operation.modifyRecordsCompletionBlock = {records, _, error in
        guard error == nil else {
          print(#line, error!.localizedDescription)
          return
        }
        guard let records = records else {
          return
        }
        print(#line, records)
      }
      self.db.add(operation)
    }
  }
  
  func delete() {
    read { (record) in
      let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
      operation.perRecordCompletionBlock = { record, error in
        guard error == nil else {
          print(#line, error!.localizedDescription)
          return
        }
        print(#line, record)
      }
      operation.modifyRecordsCompletionBlock = {records, _, error in
        guard error == nil else {
          print(#line, error!.localizedDescription)
          return
        }
        guard let records = records else {
          return
        }
        print(#line, records)
      }
      self.db.add(operation)
    }
  }
  
  func setupSubscription() {
    if UserDefaults.standard.bool(forKey: R.subscriptionWasCreated) == false {
      let predicate = NSPredicate(value: true)
      let sub = CKQuerySubscription(recordType: R.Person, predicate: predicate, subscriptionID: R.subscriptionID, options: [.firesOnRecordUpdate])
      let info = CKNotificationInfo()
      info.shouldSendContentAvailable = true
      sub.notificationInfo = info
      db.save(sub) { (subscription, error) in
        guard error == nil else {
          print(#line, error!.localizedDescription)
          return
        }
        guard let subscription = subscription else {
          print(#line, "subscription nil")
          return
        }
        print(#line, subscription)
      }
      UserDefaults.standard.set(true, forKey: R.subscriptionWasCreated)
    }
  }
}
