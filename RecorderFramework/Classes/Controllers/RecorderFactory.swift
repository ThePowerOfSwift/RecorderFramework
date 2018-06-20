//
//  RecorderFactory.swift
//  Pods
//
//  Created by Stefanita Oaca on 01/11/2017.
//

public class RecorderFactory: NSObject {
    
    public class func createUserFromDict(_ dict: NSDictionary) -> User{
        let object = User()
        
        if let value:String = dict.object(forKey: "f_name") as? String {
            object.firstName = value
        }
        if let value:String = dict.object(forKey: "l_name") as? String {
            object.lastName = value
        }
        if let value:String = dict.object(forKey: "email") as? String {
            object.email = value
        }
        if let value:String = dict.object(forKey: "max_length") as? String {
            object.maxLenght = value
        }
        if let value:String = dict.object(forKey: "pic") as? String {
            object.imagePath = value
        }
        if let stringValue:String = dict.object(forKey: "play_beep") as? String {
            if let value:Bool = (stringValue == "yes" || stringValue == "true" || stringValue == "1"){
                object.playBeep = value
            }
        }
        if let stringValue:String = dict.object(forKey: "is_public") as? String {
            if let value:Bool = (stringValue == "yes" || stringValue == "true" || stringValue == "1") {
                object.isPublic = value
            }
        }
        if let value:String = dict.object(forKey: "plan") as? String {
            object.plan = value
        }
        if let value:Int = dict.object(forKey: "time") as? Int {
            object.time = value
        }
        if let value:String = dict.object(forKey: "pin_code") as? String {
            object.pin = value
        }
        return object
    }
    
    public class func createDictFromUser(_ user: User) -> NSDictionary{
        let dictNew = NSMutableDictionary(dictionary: ["l_name":user.lastName ?? "", "f_name":user.firstName ?? "", "email":user.email ?? "", "max_length":user.maxLenght ?? ""])
        dictNew["time_zone"] = user.timeZone
        dictNew["is_public"] = user.isPublic ?? ""
        dictNew["play_beep"] = user.playBeep ?? ""
        dictNew["pic"] = user.imagePath ?? ""
        dictNew["pin_code"] = user.pin ?? ""
        let dict = NSMutableDictionary(dictionary: ["data":dictNew])
        return dict
    }

    public class func createRecordFolderFromDict(_ dict: NSDictionary) -> RecordFolder{
        let object = RecordFolder()
        
        if let value:String = dict.object(forKey: "name") as? String {
            object.title = value
        }
        if let value:String = dict.object(forKey: "id") as? String {
            object.id  = value
        }
        if let value:String = dict.object(forKey: "created") as? String {
            object.created  = value
        }
        if let value:String = dict.object(forKey: "pass") as? String {
            object.password  = value
        }
        if let value:String = dict.object(forKey: "order_id") as? String {
            object.folderOrder  = Int(value)!
        }
        object.recordedItems = [RecordItem]()
        if let values:Array<NSDictionary> = dict.object(forKey: "recordedItems") as? Array<NSDictionary> {
            for dict in values{
                object.recordedItems.append(RecorderFactory.createRecordItemFromDict(dict))
            }
        }
        
        return object
    }
    
    public class func createDictFromRecordFolder(_ folder: RecordFolder) -> NSDictionary{
        let dict = NSMutableDictionary(dictionary: ["id":folder.id ?? "", "name":folder.title ?? "", "created":folder.created ?? ""])
        dict["folder_order"] = folder.folderOrder ?? ""
        dict["pass"] = folder.password ?? ""
        var array = [NSDictionary]()
        for file in folder.recordedItems{
            array.append(RecorderFactory.createDictFromRecordItem(file))
        }
        dict.setValue(array, forKey: "recordedItems")
        return dict
    }
    
    public class func createRecordItemFromDict(_ dict: NSDictionary) -> RecordItem{
        let object = RecordItem()
        if let value:String = dict.object(forKey: "folderId") as? String {
            object.folderId = value
        }
        if let value:String = dict.object(forKey: "name") as? String {
            object.text = value
        }
        if let value:String = dict.object(forKey: "id") as? String {
            object.id = value
        }
        if let value:String = dict.object(forKey: "phone") as? String {
            object.phone = value
        }
        if let value:String = dict.object(forKey: "access_number") as? String {
            object.accessNumber = value
        }
        if let value:String = dict.object(forKey: "url") as? String {
            object.url = value
        }
        if let value:String = dict.object(forKey: "share_url") as? String {
            object.shareUrl = value
        }
        if let value:String = dict.object(forKey: "credits") as? String {
            object.credits = value
        }
        if let value:String = dict.object(forKey: "duration") as? String {
            object.duration = value
        }
        if let value:Int = dict.object(forKey: "time") as? Int {
            object.time = "\(value)"
            object.lastAccessedTime = "\(value)"
        }
        if let value:String = dict.object(forKey: "f_name") as? String {
            object.firstName = value
        }
        if let value:String = dict.object(forKey: "l_name") as? String {
            object.lastName = value
        }
        if let value:String = dict.object(forKey: "phone") as? String {
            object.phoneNumber = value
        }
        if let value:String = dict.object(forKey: "email") as? String {
            object.email = value
        }
        if let value:String = dict.object(forKey: "notes") as? String {
            object.notes = value
        }
        
        if let value:String = dict.object(forKey: "tags") as? String {
            object.tags = value
        }
        if let value:String = dict.object(forKey: "is_star") as? String {
            object.isStar = value == "1"
        }
        if let value:String = dict.object(forKey: "remind_days") as? String {
            object.remindDays = value
        }
        if let value:String = dict.object(forKey: "remind_date") as? String {
            let timeInterval = Int(AppPersistentData.sharedInstance.user.timeZone)! * -60
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let newDate = dateFormatter.date(from: value)?.addingTimeInterval(TimeInterval(timeInterval))
            if newDate != nil{
                object.remindDate = dateFormatter.string(from: newDate!)
            }else{
                object.remindDate = ""
            }
        }
        if let value:String = dict.object(forKey: "free") as? String {
            object.isFree = value == "1"
        }
        if let value:Int = dict.object(forKey: "updated") as? Int {
            object.updated = "\(value)"
        }
        if let value:String = dict.object(forKey: "text") as? String {
            object.text = value
        }
        if let value:String = dict.object(forKey: "order_id") as? String {
            object.fileOrder  = Int(value)!
        }
        return object
    }
    
    public class func createDictFromRecordItem(_ file: RecordItem) -> NSDictionary{
        let dict = NSDictionary(dictionary: ["folderId":file.folderId, "name":file.text, "id":file.id, "access_number":file.accessNumber, "url":file.url, "share_url":file.shareUrl, "credits":file.credits, "duration":file.duration, "time":file.time,"f_name":file.firstName, "l_name":file.lastName, "email":file.email, "notes":file.notes, "phone":file.phoneNumber, "tags":file.tags, "remind_date":file.remindDate, "remind_days":file.remindDays, "free":file.isFree ? "1":"0","text":file.text, "order_id":file.fileOrder])
        return dict
    }
}
