//
//  TagAnnotation.swift
//  CoreDataTest
//
//  Created by Adam Hodapp on 9/3/15.
//  Copyright (c) 2015 Adam Hodapp. All rights reserved.
//

import UIKit
import MapKit

class TagAnnotation : MKPointAnnotation {
    
    enum statusOptions : Int{
        case normal = 0
        case userTagged = 1
        case userAlone = 2
        case userInRange = 3
    }
    let main : Main!
    var status = statusOptions.normal;
    let tagInfo : (CLLocation, Int, Double, Int, String)!
    init(tagInfo : (CLLocation, Int, Double, Int, String), main : Main){
        self.tagInfo = tagInfo
        self.main = main
    }
    func tagHasSameLocation(tag : (CLLocation, Int, Double, Int, String)) -> Bool {
        if(tagInfo.0.coordinate.longitude != tag.0.coordinate.longitude) {
            return false
        }
        if(tagInfo.0.coordinate.latitude != tag.0.coordinate.latitude) {
            return false
        }
        return true
    }
    @IBAction func userTaggedLocation(button : UIButton){
        main.startTaggingLocation(tagInfo.0, title: tagInfo.4)
        self.status = .userTagged
        main.mapController.updateLocation(false)
    }
    @IBAction func userLeftLocation(button : UIButton){
        main.stopTaggingLocation()
        main.setTagRange(self)
        main.mapController.updateLocation(false)
        
    }
}
