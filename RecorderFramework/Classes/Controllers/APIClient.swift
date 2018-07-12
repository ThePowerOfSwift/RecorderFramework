//
//  APIClient.swift
//  PPC
//
//  Created by Grif on 24/04/15.
//  Copyright (c) 2015 Grif. All rights reserved.
//

import Foundation

let API_BASE_URL = "https://app2.virtualbrix.net/rapi/"
#if os(iOS)
    import CoreTelephony
#elseif os(OSX)
    
    import Cocoa
#endif

public class APIClient : NSObject {
    
    var mainSyncInProgress:Bool = false
    var mainSyncErrors:Int = 0
    
    @objc public  static let sharedInstance = APIClient()
    
    var api = Api(baseURL: API_BASE_URL)
    
    override init() {
        super.init()
        api.completionHandlerLog = { (req, resp) in
        print(req)
        print(resp)
        }
    }
    
    //default token used by server = 55942ee3894f51000530894
    public func register(_ number:String, token:String = "55942ee3894f51000530894",completionHandler:((Bool, Any?) -> Void)?)
    {
        let parameters = ["phone": number, "token": token]
        api.doRequest("register_phone", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    //{"status":"ok","phone":"+16463742122","code":"54004","msg":"Verification Code Sent"}
                    if let value = data!["phone"] as? String {
                        AppPersistentData.sharedInstance.phone = value
                    }
                    if let value = data!["api_key"] as? String {
                        AppPersistentData.sharedInstance.apiKey = value
                    }
                    if let value = data!["code"] as? String {
                        AppPersistentData.sharedInstance.verificationCode = value
                    }
                    
                    AppPersistentData.sharedInstance.saveData()
                    
                    if completionHandler != nil {
                        completionHandler!(true, AppPersistentData.sharedInstance.verificationCode)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func sendVerificationCode(_ code:String, completionHandler:((Bool, Any?) -> Void)?) {
        // either recorder or reminder
        var appCode = "rec"
        if RecorderFrameworkManager.sharedInstance.isRecorder{
            appCode = "rem"
        }
        
        //no notifications on iOS simulator
        let deviceToken =  AppPersistentData.sharedInstance.notificationToken == nil ? "Simulator" : AppPersistentData.sharedInstance.notificationToken! //used for push notifications
        var parameters = ["phone": AppPersistentData.sharedInstance.phone!,"mcc":"300" ,"code": code, "token": "55942ee3894f51000530894", "app": appCode, "device_token":deviceToken] as [String : Any]
        //default token used by server = 55942ee3894f51000530894
        #if os(iOS)
        // find country code by using the phone carrie, default value 300
            let tn = CTTelephonyNetworkInfo();
            let carrier = tn.subscriberCellularProvider
            var mcc = "300"
            if carrier != nil && carrier!.mobileCountryCode != nil{
                mcc = (carrier != nil && !carrier!.mobileCountryCode!.isEmpty) ? carrier!.mobileCountryCode! : "300"
            }
            parameters["mcc"] = mcc
            parameters["device_type"] = "ios"
        #elseif os(OSX)
            parameters["device_type"] = "mac"
            parameters["device_id"] = RecorderFrameworkManager.sharedInstance.macSN // device identifier for pn
        #elseif os(tvOS)
            parameters["mcc"] = "300"
            parameters["device_type"] = "ios"
        #endif
        parameters["time_zone"] = TimeZone.current.secondsFromGMT() / 60 // used to determine when to send pn for remind date
        api.doRequest("verify_phone", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    //{"status":"ok","phone":"+16463742122","api_key":"557872b508520557872b50855c","msg":"Phone Verified"}
                    if let value:String = data!["api_key"] as? String  {
                        AppPersistentData.sharedInstance.apiKey = value
                        AppPersistentData.sharedInstance.invalidAPIKey = false
                        AppPersistentData.sharedInstance.saveData()
                        #if os(iOS)
                        WatchKitController.sharedInstance.sendApiKey()
                        #endif
                        if completionHandler != nil {
                            completionHandler!( true, data)
                        }
                    } else{
                        if completionHandler != nil {
                            if let strError:String = data!["msg"] as? String  {
                                completionHandler!(false, strError.localized as AnyObject)
                            }
                            else {
                                completionHandler!(false, nil)
                            }
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    // for unit tests
    public func sendVerificationCode(parameters: [String: Any] ,completionHandler:((Bool, Any?) -> Void)?) {
        api.doRequest("verify_phone", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let value:String = data!["api_key"] as? String  {
                        AppPersistentData.sharedInstance.apiKey = value
                        AppPersistentData.sharedInstance.invalidAPIKey = false
                        AppPersistentData.sharedInstance.saveData()
                        
                        if completionHandler != nil {
                            completionHandler!( true, data)
                        }
                    } else{
                        if completionHandler != nil {
                            if let strError:String = data!["msg"] as? String  {
                                completionHandler!(false, strError.localized as AnyObject)
                            }
                            else {
                                completionHandler!(false, nil)
                            }
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func getRecordings(_ folderId:String!, lastFileId: String! = nil, less: Bool = false, pass:String! = nil, q:String! = nil, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String : Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "reminder":"true"]
        if folderId != nil {
            parameters.updateValue(folderId!, forKey: "folder_id")
        }

        parameters["source"] = "all"
        if lastFileId != nil{
            parameters["id"] = lastFileId!
            parameters["op"] = less ? "less" : "grater"
        }
        if pass != nil{
            parameters["pass"] = pass!
        }
        
        if q != nil{
            parameters["q"] = q!
        }
        /*
 
         folder_id=all  //get all files
         folder_id=trash //get deleted files source=all  // all or app2 or do not set source param
         pass=1234  //required for private folders
         reminder=true // for getting file reminders
         q=hello //search transcription text
         id=10,
         op=less , default is 'greater'
 
         */
        api.doRequest("get_files", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    /*
                     {
                     "status": "ok",
                     "files": [
                     {
                     "id": "12",
                     "access_number": "",
                     "name": "Untitled4",
                     "f_name": "",
                     "l_name": "",
                     "email": "",
                     "phone": "",
                     "notes": "notes",
                     "meta": "",
                     "source": "",
                     "url": "https://app2.virtualbrix.net/records/player/file/32/557931e49b4f9_1434005988_71056787.mp3",
                     "credits": "0",
                     "duration": "1",
                     "time": "1434005988",
                     "share_url": "https://app2.virtualbrix.net/records/player/file/32/557931e49b4f9_1434005988_71056787.mp3",
                     "download_url": "https://app2.virtualbrix.net/records/player/file/32/download/557931e49b4f9_1434005988_71056787.mp3"
                     }
                     ],
                     "credits": 993
                     }

                     */
                    if let calls:Array<NSDictionary> = data!["files"] as? Array<NSDictionary> {
                        var allIds:Array<String> = Array<String>()
                        var recordFolder = RecordingsManager.sharedInstance.recordFolders[0]
                        for recFolder in RecordingsManager.sharedInstance.recordFolders {
                            if recFolder.id == folderId {
                                recordFolder = recFolder
                                break
                            }
                        }
                        for item in recordFolder.recordedItems {
                            let action:Action! = item.recordingNextAction(nil)
                            if action != nil {
                                allIds.append(item.id)
                            }
                        }
                        
                        for call in calls {
                            let item = RecorderFactory.createRecordItemFromDict(call)
                            if folderId == "trash"{
                                item.fromTrash = true
                            }
                            allIds.append(item.id)
                            
                            _ = RecordingsManager.sharedInstance.syncRecordingItem(item, folder:recordFolder)
                            
                            var on = UserDefaults.standard.object(forKey: "3GSync") as? Bool
                            if(on == nil){
                                on = true
                            }
                        }
                        
                        RecordingsManager.sharedInstance.updateAllFilesFolder()
                        AppPersistentData.sharedInstance.saveData()
                    }
                    
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
        
    }
    
    func searchRecordings(_ q:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String : Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "reminder":"true"]
        parameters["q"] = q
        /*
         
         folder_id=all  //get all files
         folder_id=trash //get deleted files source=all  // all or app2 or do not set source param
         pass=1234  //required for private folders
         reminder=true // for getting file reminders
         q=hello //search transcription text
         id=10,
         op=less , default is 'greater'
         
         */
        api.doRequest("get_files", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    /*
                     {
                     "status": "ok",
                     "files": [
                     {
                     "id": "12",
                     "access_number": "",
                     "name": "Untitled4",
                     "f_name": "",
                     "l_name": "",
                     "email": "",
                     "phone": "",
                     "notes": "notes",
                     "meta": "",
                     "source": "",
                     "url": "https://app2.virtualbrix.net/records/player/file/32/557931e49b4f9_1434005988_71056787.mp3",
                     "credits": "0",
                     "duration": "1",
                     "time": "1434005988",
                     "share_url": "https://app2.virtualbrix.net/records/player/file/32/557931e49b4f9_1434005988_71056787.mp3",
                     "download_url": "https://app2.virtualbrix.net/records/player/file/32/download/557931e49b4f9_1434005988_71056787.mp3"
                     }
                     ],
                     "credits": 993
                     }
                     
                     */
                    if let calls:Array<NSDictionary> = data!["files"] as? Array<NSDictionary> {

                        var items = [RecordItem]()
                        for call in calls {
                            let item = RecorderFactory.createRecordItemFromDict(call)
                            items.append(item)
                        }
                        if completionHandler != nil {
                            completionHandler!( true, items)
                        }
                        return
                    }
                    
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
        
    }
    
    public func getRecordings(parameters: [String:Any], completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        api.doRequest("get_files", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
        
    }
    
    func getPhoneNumbers(_ completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key")
            return
        }
        
        let parameters = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        var defaultPhone = " "
        for phoneNumber in AppPersistentData.sharedInstance.phoneNumbers{
            if phoneNumber.isDefault{
                defaultPhone = phoneNumber.phoneNumber
                break
            }
        }
        AppPersistentData.sharedInstance.phoneNumbers.removeAll(keepingCapacity: false)
        
        api.doRequest("get_phones", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let numbers:Array<NSDictionary> = data!["root"] as? Array<NSDictionary> {
                        
                        for number in numbers {
                            let phoneNumber = PhoneNumber()
                            if let value:String = number.object(forKey: "phone_number") as? String {
                                phoneNumber.phoneNumber = value
                            }
                            if let value:String = number.object(forKey: "number") as? String {
                                phoneNumber.number = value
                            }
                            if let value:String = number.object(forKey: "prefix") as? String {
                                phoneNumber.prefix = value
                            }
                            if let value:String = number.object(forKey: "friendly_name") as? String {
                                phoneNumber.friendlyNumber = value
                            }
                            if let value:String = number.object(forKey: "flag") as? String {
                                phoneNumber.flag = value
                            }
                            if let value:String = number.object(forKey: "country") as? String {
                                phoneNumber.country = value
                            }
                            if let value:String = number.object(forKey: "city") as? String {
                                phoneNumber.city = value
                            }
                            
                            AppPersistentData.sharedInstance.phoneNumbers.append(phoneNumber)
                        }
                    }
                    if AppPersistentData.sharedInstance.phoneNumbers.count > 0{
                        var found = false
                        for phoneNumber in AppPersistentData.sharedInstance.phoneNumbers{
                            if phoneNumber.phoneNumber == defaultPhone{
                                phoneNumber.isDefault = true
                                found = true
                                break
                            }
                        }
                        
                        if !found{
                            AppPersistentData.sharedInstance.phoneNumbers.first!.isDefault = true
                        }
                        #if os(iOS)
                        WatchKitController.sharedInstance.sendPhone()
                        #endif
                    }
                    var downloadsCompleted = 0
                    for phoneNumber in  AppPersistentData.sharedInstance.phoneNumbers {
                        let fileManager = FileManager.default
                        var path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: RecorderFrameworkManager.sharedInstance.containerName)!.path
                        path = path.appendingFormat("/" + "flags" + "/");
                        do {
                            if !FileManager.default.fileExists(atPath: path) {
                                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                            }
                        }
                        catch {
                            
                        }
                        path = path.appendingFormat(phoneNumber.flag.components(separatedBy: "/").last!)
                        if !FileManager.default.fileExists(atPath: path) {
                            APIClient.sharedInstance.downloadFile(phoneNumber.flag!, localPath:path, completionHandler: { (success) -> Void in
                                downloadsCompleted += 1
                                if(downloadsCompleted == AppPersistentData.sharedInstance.phoneNumbers.count){
                                    if completionHandler != nil {
                                        completionHandler!( true, nil)
                                    }
                                }
                            })
                        }
                        else{
                            downloadsCompleted += 1
                            if(downloadsCompleted == AppPersistentData.sharedInstance.phoneNumbers.count){
                                if completionHandler != nil {
                                    completionHandler!( true, nil)
                                }
                            }
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func getFolders(_ completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        if AppPersistentData.sharedInstance.apiKey == nil {
            if completionHandler != nil {
                completionHandler!(false, nil)
            }
            
            return
        }
        let parameters = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        
        api.doRequest("get_folders", method: .post, parameters: parameters) { (success, data) in
            var foundDefault = false
            var foundAllFiles = false
            var foundTrash = false
            for recordFolder in RecordingsManager.sharedInstance.recordFolders {
                if recordFolder.id == "0" {
                    foundDefault = true
                    if foundAllFiles && foundDefault && foundTrash{
                        break
                    }
                }
                if recordFolder.id == "-99" {
                    foundAllFiles = true
                    if foundAllFiles && foundDefault && foundTrash{
                        break
                    }
                }
                if recordFolder.id == "trash" {
                    foundTrash = true
                    if foundAllFiles && foundDefault && foundTrash{
                        break
                    }
                }
            }
            
            if !foundDefault {
                let defaultFolder = RecordFolder()
                defaultFolder.id = "0"
                defaultFolder.title = "New Call Recordings".localized
                RecordingsManager.sharedInstance.recordFolders.insert(defaultFolder, at: 0)
            }
            if !foundAllFiles {
                let defaultFolder = RecordFolder()
                defaultFolder.id = "-99"
                defaultFolder.title = "All Files".localized
                RecordingsManager.sharedInstance.recordFolders.insert(defaultFolder, at: 1)
            }
            if !foundTrash {
                let defaultFolder = RecordFolder()
                defaultFolder.id = "trash"
                defaultFolder.title = "Trash".localized
                RecordingsManager.sharedInstance.recordFolders.insert(defaultFolder, at: 2)
            }
            
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let folders:Array<NSDictionary> = data!["folders"] as? Array<NSDictionary> {
                        var ids:Array<String> = Array<String>()
                        ids.append("0")
                        ids.append("-99")
                        ids.append("trash")
                        for folder in folders {
                            let recordFolder = RecorderFactory.createRecordFolderFromDict(folder)
                            ids.append(recordFolder.id)
                            
                            _ = RecordingsManager.sharedInstance.syncItem(recordFolder)
                        }
                        RecordingsManager.sharedInstance.keepOnlyItemsWithIds(ids);
                        RecordingsManager.sharedInstance.updateTrashFolder()
                        RecordingsManager.sharedInstance.sortByFolderOrder()
                    }
                    #if os(iOS)
                    WatchKitController.sharedInstance.sendFolders()
                    #endif
                    if completionHandler != nil {
                        completionHandler!( true, RecordingsManager.sharedInstance.recordFolders)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func createFolder(_ name:String, localID:String , pass:String! = nil, completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters = ["api_key": AppPersistentData.sharedInstance.apiKey!, "name" : name] as [String : Any]
        if pass != nil{
            parameters["pass"] = pass
        }
        
        api.doRequest("create_folder", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    var recordFolder = RecordingsManager.sharedInstance.getFolderWithId(localID as String)
                    if recordFolder == nil {
                        recordFolder = RecordFolder()
                    }
                    
                    if let value:String = data!["name"] as? String {
                        recordFolder?.title = value
                    }
                    else {
                        recordFolder?.title = name as String
                    }
                    if let value:NSNumber = data!["id"] as? NSNumber {
                        recordFolder?.id = value.stringValue
                        for action in ActionsSyncManager.sharedInstance.actions {
                            if action.arg1 != nil && action.arg1 == localID as String {
                                action.arg1 = recordFolder?.id
                            }
                            
                            if action.arg2 != nil && action.arg2 == localID as String {
                                action.arg2 = recordFolder?.id
                            }
                        }
                    }
                    _ = RecordingsManager.sharedInstance.syncItem(recordFolder!)
                    
                    if let value:NSNumber = data!["id"] as? NSNumber {
                        if completionHandler != nil {
                            completionHandler!( true, value)
                        }
                    }else{
                        if completionHandler != nil {
                            completionHandler!( true, nil)
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func deleteFolder(_ folderId:String, moveTo:String!, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "id" : folderId]
        if moveTo != nil && moveTo != ""{
            parameters["move_to"] = moveTo
        }
        
        api.doRequest("delete_folder", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        //{"status":"ok","msg":"Deleted Successfully"}
                        completionHandler!( true, nil)
                        APIClient.sharedInstance.updateFolders({ (success) -> Void in
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotificationRecordingsUpdated), object: nil)
                        })
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func reorderFolders(_ parameters:[String:Any], completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var params = parameters
        params["api_key"] = AppPersistentData.sharedInstance.apiKey!
        
        api.doRequest("update_order", method: .post, parameters: params) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                        self.updateFolders({ (success) -> Void in
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotificationRecordingsUpdated), object: nil)
                        })
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func renameFolder(_ folderId:String, name:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "id" : folderId, "name" : name]
        
        api.doRequest("update_folder", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func addPasswordToFolder(_ folderId:String, pass:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "id" : folderId, "pass" : pass, ]
        
        api.doRequest("update_folder", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func deleteRecording(_ recordItemId:String, removeForever:Bool, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "ids" : recordItemId, "action" : removeForever ? "remove_forever" : ""]
        /*
         if  action=remove_forever then file will be removed permanently
         comma separated ids limit is 30
         */
        api.doRequest("delete_files", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func moveRecording(_ recordItem:RecordItem, folderId:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "id" : recordItem.id!, "folder_id" : folderId]
        
        api.doRequest("update_file", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func recoverRecording(_ recordItem:RecordItem, folderId:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "id" : recordItem.id, "folder_id" : folderId]
        
        api.doRequest("recover_file", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func updateRecordingInfo(_ recordItem:RecordItem ,parameters:[String:Any], completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        //parameters.setObject(AppPersistentData.sharedInstance.apiKey, forKey: "api_key" as NSCopying)
        
        var params = parameters
        params["api_key"] = AppPersistentData.sharedInstance.apiKey!
        
        api.doRequest("update_file", method: .post, parameters: params) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    
    func star(_ star:Bool, entityId:String, isFile:Bool, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var params = [String:Any]()
        params["api_key"] = AppPersistentData.sharedInstance.apiKey!
        params["type"] = isFile ? "file" : "folder"
        params["id"] = entityId
        params["star"] = star ? 1 : 0
        
        api.doRequest("update_star", method: .post, parameters: params) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    // for unit tests
    public func star(_ parameters:[String:Any], completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        api.doRequest("update_star", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func cloneFile(entityId:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var params = [String:Any]()
        params["api_key"] = AppPersistentData.sharedInstance.apiKey!
        params["id"] = entityId
        
        api.doRequest("clone_file", method: .post, parameters: params) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let id = data!["id"]{
                        if completionHandler != nil {
                            completionHandler!( true, "\(id)")
                        }
                    }else{
                        if completionHandler != nil {
                            completionHandler!( true, nil)
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func renameRecording(_ recordItem:RecordItem, name:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "id" : recordItem.id!, "name":name]
        
        api.doRequest("update_file", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func uploadRecording(_ recordItem:RecordItem!, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        if recordItem.localFile == nil{
            return
        }
        
        let fileManager = FileManager.default
        var path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: RecorderFrameworkManager.sharedInstance.containerName)!.path
        path += recordItem.localFile
        
        if URL(fileURLWithPath:path).pathExtension == "caf" {
            let wavPath = path.replacingOccurrences(of: ".caf", with: ".wav", options: NSString.CompareOptions.literal, range: nil)
            //                AudioConverter.exportAsset(asWaveFormat: path, destination:wavPath)
            path = wavPath
        }
        
        if !FileManager.default.fileExists(atPath: path ){
            completionHandler!(false, nil)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "data": "{\"name\":\"\(recordItem!.text!)\",\"notes\":\"\(recordItem!.notes!)\",\"tags\":\"\(recordItem!.tags)\"}"]
        if recordItem.id != nil{
            parameters["id"] = recordItem.id
        }
        
        var source = "rec"
        if RecorderFrameworkManager.sharedInstance.isRecorder{
            source = "rem"
        }
        parameters["source"] = source
        
        api.upload(API_BASE_URL + "create_file", imagesFiles: [path], fieldNames: ["file"], parameters:parameters) { (success, retData) in
            if success {
                if let data = retData as? [String:Any] {
                    if data["status"] != nil && (data["status"] as? String) != "ok" {
                        if let strError = data["msg"] as? String {
                            if completionHandler != nil {
                                completionHandler!(false, strError.localized)
                            }
                        }
                        else {
                            if completionHandler != nil {
                                completionHandler!(false, nil)
                            }
                        }
                    }
                    else {
                        //{"status":"ok","msg":”File Uploaded Successfully",”id”:”1”}
                        if let value:NSNumber = data["id"] as? NSNumber  {
                            recordItem.id = String(format:"%.0f", value.doubleValue)
                        }
                        
                        if completionHandler != nil {
                            completionHandler!( true, recordItem.id)
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    if retData is String {
                        completionHandler!(success, retData)
                    }
                    else {
                        completionHandler!(success, "Error occured while uploading file.")
                    }
                }
            }
        }
    }
    
    func downloadFile(_ fileUrl:String, localPath:String, completionHandler:((Bool) -> Void)?)
    {
        if (AppPersistentData.sharedInstance.invalidAPIKey || fileUrl == ""){
            completionHandler!(false)
            return
        }
        
        var url = fileUrl as String
        url += "?api_key=" + AppPersistentData.sharedInstance.apiKey!
        
        api.downloadFile(url, atPath: localPath) { (success, data) in
            if completionHandler != nil {
                completionHandler!(success)
            }
        }
    }
    
    public func downloadAudioFile(_ recordItem:RecordItem, toFolder:String, completionHandler:((Bool) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false)
            return
        }
        
        let fileManager = FileManager.default
        var path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: RecorderFrameworkManager.sharedInstance.containerName)!.path
        path = path + ("/" + toFolder + "/");
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                
            }
        }
        path = path + recordItem.url.components(separatedBy: "/").last!
        
        var isWav = false
        var isMP3 = false
        if path.range(of: ".wav") != nil {
            isWav = true
        }
        
        if path.range(of: ".mp3") != nil {
            isMP3 = true
        }
        if !isWav && !isMP3 {
            path = path + ".wav"
        }
        
        // improve: remove local file if already exist and download it again (it may be a broken file)
        
        if !FileManager.default.fileExists(atPath: path) {
            APIClient.sharedInstance.downloadFile(recordItem.url!, localPath:path, completionHandler: { (success) -> Void in
                recordItem.fileDownloaded = success
                if success {
                    recordItem.localFile = "/" + toFolder + "/" + recordItem.url.components(separatedBy: "/").last!
                    var isWav = false
                    var isMP3 = false
                    if recordItem.localFile.range(of: ".wav") != nil {
                        isWav = true
                    }
                    
                    if recordItem.localFile.range(of: ".mp3") != nil {
                        isMP3 = true
                    }
                    if !isWav && !isMP3 {
                        recordItem.localFile = recordItem.localFile + ".wav"
                    }
                    var fileSize = UInt64(0)
                    do {
                        let attr = try FileManager.default.attributesOfItem(atPath: path)
                        fileSize = attr[FileAttributeKey.size] as! UInt64
                    } catch {
                        print("Error: \(error)")
                    }
                    recordItem.fileSize = "\(fileSize/1000)"
                    self.getMetadataForRecordItem(recordItem,path:path, masterCompletionHandler: nil)
                    completionHandler!(true)
                }else{
                    completionHandler!(false)
                }
            })
        }
        else {
            recordItem.fileDownloaded = true
            recordItem.localFile = "/" + toFolder + "/" + recordItem.url.components(separatedBy: "/").last!
            var isWav = false
            var isMP3 = false
            if recordItem.localFile.range(of: ".wav") != nil {
                isWav = true
            }
            
            if recordItem.localFile.range(of: ".mp3") != nil {
                isMP3 = true
            }
            if !isWav && !isMP3 {
                recordItem.localFile = recordItem.localFile + ".wav"
            }
            var fileSize = UInt64(0)
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: path)
                fileSize = attr[FileAttributeKey.size] as! UInt64
            } catch {
                print("Error: \(error)")
            }
            recordItem.fileSize = "\(fileSize/1000)"
            self.getMetadataForRecordItem(recordItem,path:path, masterCompletionHandler: nil)
            completionHandler!(true)
        }
    }
    
    func getMetadataForRecordItem(_ recordItem: RecordItem, path: String, masterCompletionHandler:((Bool) -> Void)?){
        NSLog(path)
        self.getMetadataFiles(recordItem, completionHandler: { (success, files) -> Void in
            if success && files != nil {
                let allFiles = files as! Array<NSDictionary>
                for file in allFiles{
                    let url = (file.object(forKey: "file") as? String)!
                    let name = (file.object(forKey: "name") as? String)!
                    var metaPath = AudioFileTagManager.sharedInstance.getMetadataFilePath(path)
                    if url.components(separatedBy: ".").last != "json" {
                        metaPath = RecorderFrameworkManager.sharedInstance.getPath() + recordItem.localFile.components(separatedBy: ".").first! + "/" + ((file.object(forKey: "id") as? String)!) + "." + url.components(separatedBy: ".").last!
                    }else{
                        recordItem.metaFileId = (file.object(forKey: "id") as? String)!
                    }
                    
                    APIClient.sharedInstance.downloadFile(url, localPath:metaPath, completionHandler: { (success) -> Void in
                        if(success){
                            recordItem.setupWithFile(path)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotificationRecordingsUpdated), object: nil)
                            AppPersistentData.sharedInstance.saveData()
                        }
                    })
                    if masterCompletionHandler != nil{
                        masterCompletionHandler!(true)
                    }
                }
            }
            else{
                if masterCompletionHandler != nil{
                    masterCompletionHandler!(false)
                }
            }
        })
    }
    
    public func defaultFolderSync(_ completionHandler:((Bool) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false)
            return
        }
        
        if mainSyncInProgress {
            if completionHandler != nil {
                completionHandler!(false)
            }
            return
        }
        if AppPersistentData.sharedInstance.apiKey == nil {
            mainSyncInProgress = false
            if completionHandler != nil {
                completionHandler!(false)
            }
            return
        }
        var lastRecording:RecordItem!
        if let folder = RecordingsManager.sharedInstance.recordFolders.first{
            if let rec = folder.recordedItems.first{
                lastRecording = rec
            }
        }
        if lastRecording != nil {
            APIClient.sharedInstance.getRecordings("0", lastFileId: lastRecording.id, completionHandler:{ (success, data) -> Void in
                RecordingsManager.sharedInstance.updateAllFilesFolder()
                if completionHandler != nil {
                    completionHandler!(success)
                }
            })
        }else{
            
        }
    }
    
    func mainSync(_ completionHandler:((Bool) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false)
            return
        }
        
        if mainSyncInProgress {
            if completionHandler != nil {
                completionHandler!(false)
            }
            return
        }
        if AppPersistentData.sharedInstance.apiKey == nil {
            mainSyncInProgress = false
            if completionHandler != nil {
                completionHandler!(false)
            }
            return
            //            AppPersistentData.sharedInstance.apiKey = "562a60677fd88562a60677fdc4"
        }
        mainSyncInProgress = true
        mainSyncErrors = 0
        
        APIClient.sharedInstance.getSettings({ (success, data) -> Void in
            APIClient.sharedInstance.getMessages({ (success, data) -> Void in
                APIClient.sharedInstance.getLanguages { (success, data) -> Void in
                    APIClient.sharedInstance.getTranslations(TranslationManager.sharedInstance.currentLanguage, completionHandler:{ (success, data) -> Void in
                        APIClient.sharedInstance.getProfile({ (success, data) -> Void in
                            APIClient.sharedInstance.getPhoneNumbers { (success, data) -> Void in
                                if !success {
                                    self.mainSyncErrors += 1
                                }
                                APIClient.sharedInstance.getFolders({ (success, data) -> Void in
                                    if !success {
                                        self.mainSyncErrors += 1
                                    }
                                    
                                    self.getRecordings({ (success) -> Void in
                                        if completionHandler != nil {
                                            completionHandler!(true)
                                        }
                                        self.mainSyncInProgress = false
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: kNotificationRecordingsUpdated), object: nil)
                                    })
                                })
                            }
                        })
                    })
                }
            })
        })
    }
    
    func updateFolders(_ completionHandler:((Bool) -> Void)?) {
        APIClient.sharedInstance.getFolders { (success, data) -> Void in
            if !success {
                return
            }
            APIClient.sharedInstance.getRecordings({ (success) -> Void in
                if completionHandler != nil {
                    completionHandler!(true)
                }
            })
        }
    }
    
    func getRecordings(_ completionHandler:((Bool) -> Void)?) {
        if AppPersistentData.sharedInstance.apiKey == nil {
            if completionHandler != nil {
                completionHandler!(false)
                return
            }
        }
        var countToHandle = RecordingsManager.sharedInstance.recordFolders.count - 1
        
        for recordFolder in RecordingsManager.sharedInstance.recordFolders {
            if recordFolder.id == "-99"{
                continue
            }
            APIClient.sharedInstance.getRecordings(recordFolder.id, completionHandler:{ (success, data) -> Void in
                if !success {
                    self.mainSyncErrors += 1
                }
                countToHandle -= 1
                if countToHandle <= 0 {
                    RecordingsManager.sharedInstance.updateAllFilesFolder()
                    if completionHandler != nil {
                        completionHandler!(true)
                    }
                }
            })
        }
    }
    
    func updateSettings(_ playBeep:Bool, filesPersmission:Bool = true,completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "play_beep" : playBeep ? "yes" : "no", "files_permission" : filesPersmission ? "public":"private"]
        
        api.doRequest("update_settings", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func updateUser(_ free:Bool, timezone:String! = nil, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "app" : free ? "free" : "pro"]
        if timezone != nil{
            parameters["timezone"] = timezone
        }
        
        api.doRequest("update_user", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func getSettings(_ completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        
        api.doRequest("get_settings", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let settings:NSDictionary = data!["settings"] as? NSDictionary {
                        if let value:String = settings.object(forKey: "play_beep") as? String {
                            AppPersistentData.sharedInstance.user.playBeep = value == "no" ? false:true
                        }
                        if let value:String = settings.object(forKey: "files_permission") as? String {
                            AppPersistentData.sharedInstance.filePermission = value
                        }
                        if let value:Int = data!["credits"] as? Int {
                            AppPersistentData.sharedInstance.credits = value
                        }
                        if let value:String = data!["app"] as? String {
                            AppPersistentData.sharedInstance.app = value
                        }
                        AppPersistentData.sharedInstance.user.timeZone = "\(TimeZone.current.secondsFromGMT() / 60)"
                        AppPersistentData.sharedInstance.saveData()
                    }
                    
                    if completionHandler != nil {
                        completionHandler!( true, data!["settings"])
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func buyCredits(_ credits:Int, receipt:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        var appCode = "rec"
        if RecorderFrameworkManager.sharedInstance.isRecorder{
            appCode = "rem"
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "app":appCode, "reciept" : receipt] as [String : Any]
        
        api.doRequest("buy_credits", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func buyCredits(_ parameters:[String: Any], completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }

        api.doRequest("buy_credits", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func updateToken(_ token:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "device_token" : token, "device_type" : "ios"]
        
        api.doRequest("update_device_token", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func updateToken(_ parameters:[String:Any], completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        api.doRequest("update_device_token", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func notifyUser(_ token:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "device" : token, "title" : "Title", "body" : "body"]
        
        api.doRequest("notify_user", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func getTranslations(_ language:String,completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "language": language]
        
        api.doRequest("get_translations", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, data)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func getLanguages(_ completionHandler:((Bool, Any?) -> Void)?){
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        
        api.doRequest("get_languages", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let calls:Array<NSDictionary> = data!["languages"] as? Array<NSDictionary> {
                        TranslationManager.sharedInstance.languages = Array()
                        for call in calls {
                            let item:Language = Language()
                            
                            if let value:String = call.object(forKey: "name") as? String {
                                item.name = value
                            }
                            if let value:String = call.object(forKey: "code") as? String {
                                item.code = value
                            }
                            TranslationManager.sharedInstance.languages.append(item)
                        }
                        AppPersistentData.sharedInstance.saveData()
                    }
                    
                    if completionHandler != nil {
                        completionHandler!( true, TranslationManager.sharedInstance.languages)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    @objc func getMessages(_ completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let defaults = UserDefaults.standard
        let lastTime = defaults.object(forKey: "messageTime")
//        if lastTime != nil{
//            if ((lastTime as! NSNumber).intValue - (Date().timeIntervalSince1970 as NSNumber).intValue) < 24 * 60 * 60{
//                completionHandler!( true, nil)
//                return
//            }
//        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        
        api.doRequest("get_msgs", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let msgs:Array<NSDictionary> = data!["msgs"] as? Array<NSDictionary> {
                        
                        defaults.set(NSNumber(value: NSDate().timeIntervalSince1970), forKey: "messageTime")
                        
                        for msg in msgs {
                            let item:ServerMessage = ServerMessage()
                            
                            if let value:String = msg.object(forKey: "id") as? String {
                                item.id = value
                            }
                            if let value:String = msg.object(forKey: "title") as? String {
                                item.title = value
                            }
                            if let value:String = msg.object(forKey: "body") as? String {
                                item.body = value
                            }
                            if let value:String = msg.object(forKey: "time") as? String {
                                item.time = value
                            }
                            
                            var found = false
                            for msg in AppPersistentData.sharedInstance.serverMessages{
                                if msg.id == item.id{
                                    found = true
                                    break
                                }
                            }
                            
                            if !found{
                                item.read = false
                                if lastTime == nil{
                                    item.read = true
                                }
                                AppPersistentData.sharedInstance.serverMessages.append(item)
                            }
                            
                        }
                        AppPersistentData.sharedInstance.serverMessages.sort { $0.time < $1.time }
                        AppPersistentData.sharedInstance.saveData()
                    }
                    
                    if completionHandler != nil {
                        completionHandler!( true, AppPersistentData.sharedInstance.serverMessages)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func uploadMetadataImageFile(_ imagePath:String, fileId: String, oldId:String! = nil, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!,"name":fileId+"_metadata_" + UUID().uuidString, "parent_id":fileId]
        if oldId != nil{
            parameters["id"] = oldId!
        }
        
        if !FileManager.default.fileExists(atPath: imagePath ){
            completionHandler!(false, nil)
            return
        }
        
        api.upload(API_BASE_URL + "upload_meta_file", imagesFiles: [imagePath], fieldNames: ["file"], parameters:parameters) { (success, retData) in
            if success {
                if let data = retData as? [String:Any] {
                    if data["status"] != nil && (data["status"] as? String) != "ok" {
                        if let strError = data["msg"] as? String {
                            if completionHandler != nil {
                                completionHandler!(false, strError.localized)
                            }
                        }
                        else {
                            if completionHandler != nil {
                                completionHandler!(false, nil)
                            }
                        }
                    }
                    else {
                        
                        if completionHandler != nil {
                            completionHandler!( true, data["id"])
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    if retData is String {
                        completionHandler!(success, retData)
                    }
                    else {
                        completionHandler!(success, "Error occured while uploading file.")
                    }
                }
            }
        }
    }
    
    func uploadMetadataFile(_ recordItem:RecordItem, oldId:String! = nil, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!,"name":(recordItem.text!)+"_metadata", "parent_id":(recordItem.id!)]
        if oldId != nil{
            parameters["id"] = oldId!
        }
        let fileManager = FileManager.default
        var path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: RecorderFrameworkManager.sharedInstance.containerName)!.path
        path += recordItem.localFile
        path = AudioFileTagManager.sharedInstance.getMetadataFilePath(path)
        NSLog(path)
        if !FileManager.default.fileExists(atPath: path ){
            completionHandler!(false, nil)
            return
        }       
        
        api.upload(API_BASE_URL + "upload_meta_file", imagesFiles: [path], fieldNames: ["file"], parameters:parameters) { (success, retData) in
            if success {
                if let data = retData as? [String:Any] {
                    if data["status"] != nil && (data["status"] as? String) != "ok" {
                        if let strError = data["msg"] as? String {
                            if completionHandler != nil {
                                completionHandler!(false, strError.localized)
                            }
                        }
                        else {
                            if completionHandler != nil {
                                completionHandler!(false, nil)
                            }
                        }
                    }
                    else {
                        
                        if completionHandler != nil {
                            if path.contains("json"){
                                recordItem.metaFileId = "\(data["id"]!)"
                            }
                            completionHandler!( true, nil)
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    if retData is String {
                        completionHandler!(success, retData)
                    }
                    else {
                        completionHandler!(success, "Error occured while uploading file.")
                    }
                }
            }
        }
    }
    
    func deleteMetadataFile(_ fileId:String, parentId: String! = nil,completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "ids":fileId]
        if parentId != nil{
            parameters["parent_id"] = parentId
        }
        
        api.doRequest("delete_meta_files", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }

    public func getMetadataFiles(_ recordItem:RecordItem, completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!, "parent_id":(recordItem.id!)]
        
        api.doRequest("get_meta_files", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, data?["meta_files"])
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
        
    }
    
    //MARK: profile
    func getProfile(_ completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        
        api.doRequest("get_profile", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if let profile:NSDictionary = data!["profile"] as? NSDictionary {
                        AppPersistentData.sharedInstance.user = RecorderFactory.createUserFromDict(profile)
                        AppPersistentData.sharedInstance.user.timeZone = "\(TimeZone.current.secondsFromGMT() / 60)"
                        AppPersistentData.sharedInstance.saveData()
                        
                        #if os(iOS)
                        WatchKitController.sharedInstance.sendUser()
                        #endif
                    }
                    
                    if let url:String = data!["share_url"] as? String {
                        AppPersistentData.sharedInstance.shareUrl = url
                    }
                    if let url:String = data!["rate_url"] as? String {
                        AppPersistentData.sharedInstance.rateUrl = url
                    }
                    if completionHandler != nil {
                        completionHandler!( true, data)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    public func updateProfile(params:[String:Any], completionHandler:((Bool, Any?) -> Void)?)
    {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters = params
        parameters["api_key"] = AppPersistentData.sharedInstance.apiKey!
        
        api.doRequest("update_profile", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
    
    func uploadProfilePicture(path:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        if !FileManager.default.fileExists(atPath: path ){
            completionHandler!(false, nil)
            return
        }
        
        let parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        var url = API_BASE_URL.replacingOccurrences(of: "rapi/", with: "upload/update_profile_img")
        api.upload(url, imagesFiles: [path], fieldNames: ["file"], parameters:parameters, mimeType: "image/jpeg") { (success, retData) in
            if success {
                if let data = retData as? [String:Any] {
                    if data["status"] != nil && (data["status"] as? String) != "ok" {
                        if let strError = data["msg"] as? String {
                            if completionHandler != nil {
                                completionHandler!(false, strError.localized)
                            }
                        }
                        else {
                            if completionHandler != nil {
                                completionHandler!(false, nil)
                            }
                        }
                    }
                    else {
                        
                        if completionHandler != nil {
                            completionHandler!( true, nil)
                        }
                    }
                }
            }
            else {
                if completionHandler != nil {
                    if retData is String {
                        completionHandler!(success, retData)
                    }
                    else {
                        completionHandler!(success, "Error occured while uploading file.")
                    }
                }
            }
        }
    }
    
    public func verifyFolderPass(_ pass:String, folderId:String, completionHandler:((Bool, Any?) -> Void)?) {
        if AppPersistentData.sharedInstance.invalidAPIKey {
            completionHandler!(false, "Invalid API Key" as AnyObject)
            return
        }
        
        var parameters:[String:Any] = ["api_key": AppPersistentData.sharedInstance.apiKey!]
        parameters["id"] = folderId
        parameters["pass"] = pass
        
        api.doRequest("verify_folder_pass", method: .post, parameters: parameters) { (success, data) in
            if success {
                if data!["status"] != nil && (data!["status"] as? String) != "ok" {
                    if let strError = data!["msg"] as? String {
                        if completionHandler != nil {
                            completionHandler!(false, strError.localized)
                        }
                    }
                    else {
                        if completionHandler != nil {
                            completionHandler!(false, nil)
                        }
                    }
                }
                else {
                    if completionHandler != nil {
                        completionHandler!( true, nil)
                    }
                }
            }
            else {
                if completionHandler != nil {
                    completionHandler!(success, data!["error"] as? String)
                }
            }
        }
    }
}

