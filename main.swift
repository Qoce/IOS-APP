//
//  Main.swift
//  LocationTag
//
//  Created by Adam Hodapp on 6/04/15.
//  Copyright (c) 2015 Adam Hodapp. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import Foundation
import AddressBookUI

class Main: NSObject, CLLocationManagerDelegate, SettingsListener {
    
    let locationManager = CLLocationManager()
    let serverStr = "173.17.20.67"
    var location : CLLocation?{
        get{
            return locationManager.location
        }
        
    }
    var mapController : MapController
    
    let debugMode = false
    
    var doesMapNeedRefresh = false
    
    var birthdayGender : (birthday : NSDate, gender : NSString)!{
        didSet{
            self.onSettingsSet()
        }
    }
    var age : Int{
        get{
            return Int(-self.birthdayGender.birthday.timeIntervalSinceDate(NSDate()) / 31557600)
        }
    }
    let formatter = NSDateFormatter()
    var myTag : (CLLocation, Int, Double, Int, String)?
    
    init(mapController: MapController) {
        self.mapController = mapController
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        super.init()
    
        determineSettings()
   
        self.locationManager.delegate = self
        self.mapController.main = self
    }
    
    var usersAnnotation : TagAnnotation!
    
    func tagLocationWithTitle(title : String) {
        if(location != nil){
            self.tagLocation(location!, title: title)
        }
        else{
            NSLog("Need Location")
        }
    }
    private func tagLocation(location : CLLocation, title : String){
        
        let improvedTitle : NSString = title.stringByReplacingOccurrencesOfString(" ", withString: "_")
        
      //  NSLog("http://localhost:21025/s\(longitude)?\(latitude)?\(self.birthdayGender.gender)?\(self.age)?\(improvedTitle)")
        let results = makeUrlRequest("http://\(serverStr):21025/s\(location.coordinate.longitude)?\(location.coordinate.latitude)?\(self.birthdayGender.gender)?\(self.age)?\(improvedTitle)")
        NSLog("Results: \(results)")
        
        
        let location = self.parseLocation(results)
        usersAnnotation = self.mapController.getTagAnnotation(location)
        usersAnnotation.status = .userTagged
        
    }
    var repeatTaggingInfo : (CLLocation, String)!
    var timer : NSTimer!
    
    func startTaggingLocation(location : CLLocation, title : String){
        stopTaggingLocation()
        repeatTaggingInfo = (location, title)
        repeatTagLocation()
        timer = NSTimer.scheduledTimerWithTimeInterval(9.1, target: self, selector: Selector("repeatTagLocation"), userInfo: nil, repeats: true)
        timer.tolerance = 1
    }
    func repeatTagLocation(){
        self.tagLocation(repeatTaggingInfo.0, title: repeatTaggingInfo.1)
    }
    func stopTaggingLocation(){
        if(timer != nil){
            timer.invalidate()
        }
        self.usersAnnotation = nil
    }
    func setTagRange(annotation : TagAnnotation){
        let maxSquaredDistance = 1.0
        let xDistance = annotation.coordinate.latitude - location!.coordinate.latitude
        let yDistance = annotation.coordinate.longitude - location!.coordinate.longitude
        let squaredDistance = xDistance * xDistance + yDistance * yDistance
        if(squaredDistance < maxSquaredDistance){
            annotation.status = .userInRange
        }
        else{
            annotation.status = .normal
        }
    }
    
    
//    func tagLocationWithTitle(title : String) {
//        
//        let improvedTitle : NSString = title.stringByReplacingOccurrencesOfString(" ", withString: "_")
//        
//        let url = NSURL(string:"http://localhost:21025/s\(self.locationManager.location?.coordinate.longitude)?\(self.locationManager.location?.coordinate.latitude)?\(self.birthdayGender.gender)?\(self.age)?\(improvedTitle)")
//        let request = NSURLRequest(URL:url!)
//        var response: NSURLResponse? = nil
//        
//        var error: NSError? = nil
//        let reply: NSData?
//        do {
//            reply = try NSURLConnection.sendSynchronousRequest(request, returningResponse:&response)
//        } catch let error1 as NSError {
//            error = error1
//            reply = nil
//        }
//        
//        
//        let results = NSString(data:reply!, encoding:NSUTF8StringEncoding)
//        NSLog("\(results)")
//        
//    }
    
    func locationManager(manager: CLLocationManager,
        didFailWithError error: NSError){
            NSLog("Error failed to get location")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if self.doesMapNeedRefresh {
            self.mapController.updateLocation(true)
            self.doesMapNeedRefresh = false
        }
    }
    
    func determineSettings(){
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        // var birthdayGender = NSEntityDescription.insertNewObjectForEntityForName("BirthdayGender", inManagedObjectContext: context) as! NSManagedObject
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("BirthdayGender", inManagedObjectContext: context)
        fetchRequest.entity = entity
        fetchRequest.returnsObjectsAsFaults = false
        
        let results : NSArray = try! context.executeFetchRequest(fetchRequest)
        
        for(var i = 0; i < results.count - 1; i++){
            context.deleteObject(results[i] as! NSManagedObject)
            print(results[i])
        }
        if results.count > 0 && !debugMode {
            print(results[0])
            let result : AnyObject = results[0]
            let birthday : NSDate = self.formatter.dateFromString(result.valueForKey("birthday") as! String)!
            let gender : NSString = result.valueForKey("gender") as! String
            self.birthdayGender = (birthday, gender)
        }
        else{
            NSLog("Result array size is 0, user will now fill in details.")
            let settingsController = self.mapController.storyboard!.instantiateViewControllerWithIdentifier("Settings") as! SettingsViewController
            settingsController.main = self
            self.mapController.navigationController!.showViewController(settingsController, sender: nil)
        }
        
        //        if let birthday : String = birthdayGender.valueForKey("birthday") as? String {
        //            NSLog("anything working?")
        //            if let gender : String = birthdayGender.valueForKey("gender") as? String {
        //                NSLog("core data working?")
        //                let formatter = NSDateFormatter()
        //
        //                if let birthDate = formatter.dateFromString(birthday){
        //                    self.model.birthdayGender = (birthDate, gender)
        //                    return;
        //                }
        //
        //            }
        //
        //        }
    }
    
    func onSettingsSet() {
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        let birthday : NSString = self.formatter.stringFromDate(self.birthdayGender.birthday)
        let gender : NSString = self.birthdayGender.gender
        
        let birthdayGender = NSEntityDescription.insertNewObjectForEntityForName("BirthdayGender", inManagedObjectContext: context) 
        
        birthdayGender.setValue(birthday, forKey: "birthday")
        birthdayGender.setValue(gender, forKey: "gender")
        
        var error : NSError? = nil
        
        do {
            try context.save()
        } catch let error1 as NSError {
            error = error1
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
    }
    
    func makeUrlRequest(str : String) -> NSString!{
        let url = NSURL(string:str)
        let request = NSURLRequest(URL:url!)
        var response: NSURLResponse? = nil

        let reply: NSData?
        do {
            reply = try NSURLConnection.sendSynchronousRequest(request, returningResponse:&response)
        } catch let error1 as NSError {
            NSLog("\(error1)")
            reply = nil
        }
        if(reply == nil) {
            return "error"
        }
        
        return NSString(data:reply!, encoding:NSUTF8StringEncoding)!
    }
    
    func parseLocation(inc: NSString) -> (CLLocation, Int, Double, Int, String){
        //Gets the location in the string of the first character after the name in the JSON file
        let latitude:Int = inc.rangeOfString("\"latitude\":").location + inc.rangeOfString("\"latitude\":").length
        let longitude:Int = inc.rangeOfString("\"longitude\":").location + inc.rangeOfString("\"longitude\":").length
        let ageAvg:Int = inc.rangeOfString("\"ageAvg\":").location + inc.rangeOfString("\"ageAvg\":").length
        let percentMale:Int = inc.rangeOfString("\"percentMale\":").location + inc.rangeOfString("\"percentMale\":").length
        let pop:Int = inc.rangeOfString("\"pop\":").location + inc.rangeOfString("\"pop\":").length
        let title:Int = inc.rangeOfString("\"title\":").location + inc.rangeOfString("\"title\":").length + 1
        
        //Gets the length of the remainder of the string after the locations from the first block
        let latLength = inc.length - latitude
        let longLength = inc.length - longitude
        let ageAvgLength = inc.length - ageAvg
        let percentMaleLength = inc.length - percentMale
        let popLength = inc.length - pop
        let titleLength = inc.length - title
        
        //Gets the ends of the required data for each variable
        let latitudeEnd = (inc.substringWithRange(NSRange(location: latitude,length: latLength)) as NSString).rangeOfString(",").location
        let longitudeEnd = (inc.substringWithRange(NSRange(location: longitude,length: longLength)) as NSString).rangeOfString(",").location
        let ageAvgEnd = (inc.substringWithRange(NSRange(location: ageAvg,length: ageAvgLength)) as NSString).rangeOfString(",").location
        let percentMaleEnd = (inc.substringWithRange(NSRange(location: percentMale,length: percentMaleLength)) as NSString).rangeOfString(",").location
        let popEnd = (inc.substringWithRange(NSRange(location: pop,length: popLength)) as NSString).rangeOfString(",").location
        let titleEnd = (inc.substringWithRange(NSRange(location: title,length: titleLength)) as NSString).rangeOfString("}").location - 1
        
        //Converts the data into strings
        let latitudeString = inc.substringWithRange(NSRange(location: latitude,length: latitudeEnd))
        let longitudeString = inc.substringWithRange(NSRange(location: longitude,length: longitudeEnd))
        let ageAvgString = inc.substringWithRange(NSRange(location: ageAvg,length: ageAvgEnd))
        let percentMaleString = inc.substringWithRange(NSRange(location: percentMale,length: percentMaleEnd))
        let popString = inc.substringWithRange(NSRange(location: pop,length: popEnd))
        let titleString = inc.substringWithRange(NSRange(location: title, length: titleEnd))
        
        return (CLLocation(latitude: (latitudeString as NSString).doubleValue, longitude: (longitudeString as NSString).doubleValue), (ageAvgString as NSString).integerValue, (percentMaleString as NSString).doubleValue, (popString as NSString).integerValue, titleString)
    }
    //Parses an entire list of locations into an array of structs
    func parseLocationList(var locList: NSString) -> [(CLLocation, Int, Double, Int, String)]{
        
        var values = [(CLLocation, Int, Double, Int, String)]()
        
        while(true){
            let start = locList.rangeOfString("{").location
            let end = locList.rangeOfString("}").location
            if start == NSNotFound || end == NSNotFound {
                break
            }
            values.append(parseLocation(locList.substringWithRange(NSRange(location: start, length: end - start + 1)) as NSString))
            locList = locList.substringWithRange(NSRange(location: end + 1, length: locList.length - end - 1))
        }
        
        return values
    }
    /*
        Runs response function with the string that was created as a parameter, after the location is aquired from the coordinates
        Note: This must not be run excessivley, after a while apple refuses to to return a value, do to excessive requests to their API (I'm not sure why)
    */
    static func getFormattedAddressFromLocation(loc : CLLocation, response: (String) -> Void) {
        let geocoder = CLGeocoder()
        var str = "Address Unobtainable"
     
        geocoder.reverseGeocodeLocation(CLLocation(latitude: loc.coordinate.latitude,longitude:  loc.coordinate.longitude)) {
            [](placemarks, error) -> Void  in
            if let placemarks = placemarks where placemarks.count > 0 {
                let dict = placemarks[0]
                str = ABCreateStringWithAddressDictionary(dict.addressDictionary!, false)
                response(str)
            }
            else{
                NSLog(String(CLLocation(latitude: loc.coordinate.latitude,  longitude: loc.coordinate.longitude)))
                response(str)
            }
        }
    }
}
