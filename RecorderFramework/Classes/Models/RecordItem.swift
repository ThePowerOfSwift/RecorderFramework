//
//  RecordItem.swift
//  Recorder
//
//  Created by Grif on 24/01/15.
//  Copyright (c) 2015 Grif. All rights reserved.
//

import UIKit

@objc public enum StorageType : Int {
    case auto = 0
    case keepLocally
    case deleteFromLocalStorage
}

public class RecordItem: NSObject, NSSecureCoding, UIActivityItemSource {
    public var text: String! = ""
    public var id:String! = ""
    public var accessNumber:String! = ""
    public var phone:String! = ""
    public var url:String! = ""
    public var credits:String! = ""
    public var duration:String! = ""
    public var time:String! = ""
    
    public var lastAccessedTime:String! = ""
    public var fileDownloaded = false
    public var localFile:String! = ""
    
    public var localMetadataFile:String! = ""
    public var metadataFilePath:String! = ""
    
    public var fromTrash = false
    
    public var waveRenderVals:NSArray!
    
    //var linkedActionId: String!
    public var shareUrl:String! = ""
    
    public var firstName: String! = ""
    public var lastName: String! = ""
    public var phoneNumber: String! = ""
    public var email: String! = ""
    public var notes: String! = ""
    public var tags: String = ""
    
    public var fileData: Data! // for airdrop
    
    public var storageType:StorageType = StorageType.auto
    
    override public init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        if let value = aDecoder.decodeObject(forKey: "title") as? String {
            self.text = value
        }
        if let value = aDecoder.decodeObject(forKey: "id") as? String {
            self.id = value
        }
        if let value = aDecoder.decodeObject(forKey: "accessNumber") as? String {
            self.accessNumber = value
        }
        if let value = aDecoder.decodeObject(forKey: "phone") as? String {
            self.phone = value
        }
        if let value = aDecoder.decodeObject(forKey: "url") as? String {
            self.url = value
        }
        if let value = aDecoder.decodeObject(forKey: "credits") as? String {
            self.credits = value
        }
        if let value = aDecoder.decodeObject(forKey: "duration") as? String {
            self.duration = value
        }
        if let value = aDecoder.decodeObject(forKey: "time") as? String {
            self.time = value
        }
        if let value = aDecoder.decodeObject(forKey: "lastAccessedTime") as? String {
            self.lastAccessedTime = value
        }
        else {
            self.lastAccessedTime = self.time
        }
        
        if let value = aDecoder.decodeObject(forKey: "localFile") as? String {
            self.localFile = value
        }
        if let value = aDecoder.decodeObject(forKey: "fileDownloaded") as? String {
            self.fileDownloaded = NSString(string: value).boolValue
        }
        if let value = aDecoder.decodeObject(forKey: "fromTrash") as? String {
            self.fromTrash = NSString(string: value).boolValue
        }
        
        if let data = aDecoder.decodeObject(forKey: "waveRenderVals") as? Data {
            if data.count > 0{
                waveRenderVals = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSArray
            }
        }
        
//        if let value = aDecoder.decodeObjectForKey("linkedActionId") as? String {
//            self.linkedActionId = value
//        }
        
        if let value = aDecoder.decodeObject(forKey: "shareUrl") as? String {
            self.shareUrl = value
        }

        if let value: AnyObject = aDecoder.decodeObject(forKey: "storageType") as? NSNumber{
            self.storageType = StorageType(rawValue: value.intValue)!
        }

        if let value = aDecoder.decodeObject(forKey: "firstName") as? String {
            self.firstName = value
        }
        if let value = aDecoder.decodeObject(forKey: "lastName") as? String {
            self.lastName = value
        }
        if let value = aDecoder.decodeObject(forKey: "phoneNumber") as? String {
            self.phoneNumber = value
        }
        if let value = aDecoder.decodeObject(forKey: "email") as? String {
            self.email = value
        }
        if let value = aDecoder.decodeObject(forKey: "notes") as? String {
            self.notes = value
        }
        
        if let value = aDecoder.decodeObject(forKey: "tags") as? String {
            self.tags = value
        }
        
        if let value = aDecoder.decodeObject(forKey: "fileData") as? Data {
            self.fileData = value
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        if let value = self.text {
            aCoder.encode(value, forKey: "title")
        }
        
        if let value = self.id {
            aCoder.encode(value, forKey: "id")
        }

        if let value = self.accessNumber {
            aCoder.encode(value, forKey: "accessNumber")
        }

        if let value = self.url {
            aCoder.encode(value, forKey: "url")
        }

        if let value = self.credits {
            aCoder.encode(value, forKey: "credits")
        }

        if let value = self.duration {
            aCoder.encode(value, forKey: "duration")
        }

        if let value = self.time {
            aCoder.encode(value, forKey: "time")
        }

        if let value = self.lastAccessedTime {
            aCoder.encode(value, forKey: "lastAccessedTime")
        }

        if let value = self.localFile {
            aCoder.encode(value, forKey: "localFile")
        }

        aCoder.encode(fileDownloaded ? "true" : "false", forKey: "fileDownloaded")
        aCoder.encode(fromTrash ? "true" : "false", forKey: "fromTrash")
        
        if waveRenderVals != nil {
            let data = NSKeyedArchiver.archivedData(withRootObject: waveRenderVals)
            aCoder.encode(data, forKey: "waveRenderVals")
        }
        
//        if let value = self.linkedActionId {
//            aCoder.encodeObject(value, forKey: "linkedActionId")
//        }
        
        if let value = self.shareUrl {
            aCoder.encode(value, forKey: "shareUrl")
        }
        
        aCoder.encode( NSNumber(value:self.storageType.rawValue), forKey: "storageType")
        
        if let value = self.firstName {
            aCoder.encode(value, forKey: "firstName")
        }
        
        if let value = self.lastName {
            aCoder.encode(value, forKey: "lastName")
        }
        
        if let value = self.phoneNumber {
            aCoder.encode(value, forKey: "phoneNumber")
        }
        
        if let value = self.email {
            aCoder.encode(value, forKey: "email")
        }
        
        if let value = self.notes {
            aCoder.encode(value, forKey: "notes")
        }
        
        aCoder.encode(tags, forKey: "tags")
        
        if let value = self.fileData {
            aCoder.encode(value, forKey: "fileData")
        }
    }
    
    static public  var supportsSecureCoding : Bool {
        return true
    }
    
    public func update(_ item:RecordItem) {
        self.text = item.text
        self.accessNumber = item.accessNumber
        if self.url != item.url {
            fileDownloaded = false
            localFile = nil
        }
        self.url = item.url
        self.credits = item.credits
        self.time = item.time
        self.duration = item.duration
        self.firstName = item.firstName
        self.lastName = item.lastName
        self.phoneNumber = item.phoneNumber
        self.email = item.email
        self.notes = item.notes
        self.tags = item.tags
        self.fromTrash = item.fromTrash
    }
    
    public func recordingNextAction(_ currentAction:Action!) -> Action! {
        var currentFound = currentAction == nil
        for action in ActionsSyncManager.sharedInstance.actions {
            if action.arg1 == self.id {
                if currentFound {
                    return action
                }
                else if currentAction == action {
                    currentFound = true
                }
            }
        }
        
        return nil
    }
    
    public func securelyArchiveRootObject() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.requiresSecureCoding = true
        
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        path += self.localFile
        
        if FileManager.default.fileExists(atPath: path) {
            self.fileData = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        
        archiver.encode(self, forKey: "AirDropRecording")
        archiver.finishEncoding()
        
        return data as Data
    }
    
    public class func securelyUnarchiveProfileWithFile(_ filePath:String) -> RecordItem {
        let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        let unarchiver = NSKeyedUnarchiver(forReadingWith: fileData!)
        
        unarchiver.requiresSecureCoding = true
        if let recItem = unarchiver.decodeObject(of: RecordItem.self, forKey: "AirDropRecording"){
            if let retRecItem = recItem as? RecordItem {
                return retRecItem
            }
        }
        
        return RecordItem()
    }
    
    //MARK: activity item
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return Data()
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        return self.securelyArchiveRootObject();
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage! {
        return UIImage(named: "airdroppreview")
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
        return "com.werockapps.callrec"
    }
}
