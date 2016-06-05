//
//  MapControllerViewController.swift
//  CoreDataTest
//
//  Created by Adam Hodapp on 7/16/15.
//  Copyright (c) 2015 Adam Hodapp. All rights reserved.
//

import UIKit
import MapKit
import Foundation

class MapController: UIViewController , MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    
    var isUpdatingLocation = true
    var main : Main!
    var connectionHasFailed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        mapView.delegate = self
        main = Main(mapController: self)
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: Selector("refresh"), userInfo: nil, repeats: false)
        timer.tolerance = 0.1
        
    }
    var shouldUpdateLocation = false
    var shouldUseFocusedLocation = false
    var suspendRefresh = false  // When true the next refresh that would occur automatically does not occur
    var focusedLocation : CLLocation? = nil
    /*
     Bug: Annotations (besides userAlone) will not update from their original position if the map is moved or refreshed while the user is not tagging their location
     Fixed: Don't put the rendering of annotations in the refresh function
     Bug: Addresses won't show up ANYWHERE after a single refresh occurrs 
    
    */
    func updateLocation(reset: Bool){
    //    NSLog("\(shouldUseFocusedLocation)")
        if(main.location == nil){
            NSLog("Need the location")
            return
        }
        let location : CLLocation
        location = main.location!
        
        let span = MKCoordinateSpanMake(1, 1)
        let region : MKCoordinateRegion
        
        if reset || !shouldUpdateLocation{
            if shouldUseFocusedLocation {
                suspendRefresh = true
                mapView.setRegion(MKCoordinateRegion(center: focusedLocation!.coordinate, span: span), animated: true)
                shouldUseFocusedLocation = false
             
            }
            else{
                suspendRefresh = true
                mapView.setRegion(MKCoordinateRegion(center: location.coordinate, span: span), animated: false)
            }
            shouldUpdateLocation = true
            region = mapView.region
            NSLog("updatedLocation")
        }
        else {
            region = mapView.region
        }
        
        do {
            let reply = main.makeUrlRequest("http://\(main.serverStr):21025/g\(region.center.longitude - region.span.longitudeDelta/2)?\(region.center.longitude + region.span.longitudeDelta/2)?\(region.center.latitude - region.span.latitudeDelta/2)?\(region.center.latitude + region.span.latitudeDelta/2)")
        
            if(reply == "error"){
                NSLog("Error in reply!!!")
                return
            }
            
            var locationsToShow : [(CLLocation, Int, Double, Int, String)]
            
            locationsToShow = main.parseLocationList(reply)
            NSLog("\(locationsToShow.count)")
            var annotationsToAdd = [TagAnnotation]()
            let annotationsToRemove = mapView.annotations
            
            for tag in locationsToShow{
                
                let annotation = self.getTagAnnotation(tag)!
                
                
                if(main.usersAnnotation != nil){
                    if(annotation.tagHasSameLocation(main.usersAnnotation.tagInfo)){
                        annotation.status = .userTagged
                    }
                }
                annotationsToAdd.append(annotation)
                
            }
            if(main.usersAnnotation == nil){
                let annotation = self.getTagAnnotation((location, 0, 0, 0, ""))!
                annotation.status = .userAlone
                annotation.title = "You are here"
                Main.getFormattedAddressFromLocation(location) {(str: String) -> Void in
                    annotation.subtitle = str
                }
                annotationsToAdd.append(annotation)
                self.mapView.addAnnotations(annotationsToAdd)
                self.mapView.removeAnnotations(annotationsToRemove)
                self.connectionHasFailed = false
            }
            else {
                mapView.addAnnotations(annotationsToAdd)
                mapView.removeAnnotations(annotationsToRemove)
                connectionHasFailed = false
            }
        }
    }
    func zoomToLocation(location : CLLocation) {
    //    self.shouldUpdateLocation = true
        self.shouldUseFocusedLocation = true
        self.focusedLocation = location
    }
    @IBAction func refresh(sender: UIButton) {
        self.refresh()
    }
    func refresh() {
        self.updateLocation(true)
    }
    var refreshQueued = false
    
    internal func queueRefresh(){
        refreshQueued = true
    }
    
    func mapView(__mapView: MKMapView, regionWillChangeAnimated animated: Bool){
        
       respondToRegionChange(mapView) 
        
    }
    func mapView(__mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        
       respondToRegionChange(mapView)
    }
    
    func respondToRegionChange(mapView: MKMapView!){
        if suspendRefresh {
            suspendRefresh = false
            return;
        }
        NSLog("responding to region change")
       // updateLocation(false)
        if self.refreshQueued {
            refresh()
            self.refreshQueued = false
        }
        else{
            updateLocation(false)

        }

    }
//    func onLocationChange(){
//        
//        if isUpdatingLocation {
//            
//            updateLocation(true)
//            
//        }
//        
//    }

    func displayConnectionError(){
        NSLog("Connection failed")
        let alert = UIAlertView()
        alert.title = "Error"
        alert.message = "No Connection"
        alert.addButtonWithTitle("Ok")
        alert.show()
        connectionHasFailed = true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //Creates annotation on screen based on tag
    func getTagAnnotation(tag : (CLLocation, Int, Double, Int, String)) -> TagAnnotation?{
        if(main.location == nil){
            NSLog("Need the location")
            return nil
        }
        let annotation = TagAnnotation(tagInfo : tag, main: self.main)
        annotation.title = tag.4
        annotation.subtitle = "Loading..."
        annotation.coordinate = CLLocationCoordinate2D(latitude: tag.0.coordinate.latitude, longitude: tag.0.coordinate.longitude)
        main.setTagRange(annotation)
            
        return annotation
    }
    @IBAction func showTagSelectView(sender: AnyObject) {
        if(main.location == nil){
            NSLog("Need the location")
            return
        }
        let delta = 1.0 //This is the radius of the square that is requested, if this is greater than 10 the request will return null
        let latMax = self.main.location!.coordinate.latitude + delta
        let longMax = self.main.location!.coordinate.longitude + delta
        let latMin = self.main.location!.coordinate.latitude - delta
        let longMin = self.main.location!.coordinate.longitude - delta
        
        
        let url = NSURL(string:"http://\(main.serverStr):21025/g\(longMin)?\(longMax)?\(latMin)?\(latMax)")
        let request = NSURLRequest(URL:url!)
        var response: NSURLResponse? = nil
        
        var error: NSError? = nil
        do {
            let reply = try NSURLConnection.sendSynchronousRequest(request, returningResponse:&response)
            
            //Latitude, Longitude, Average Age, Percentmale, Population, Title
            
            var locationsToShow : [(CLLocation, Int, Double, Int, String)]
            
            let results = NSString(data:reply, encoding:NSUTF8StringEncoding)
            
            locationsToShow = main.parseLocationList(results!)
            
            func sortFunc(loc1 : (CLLocation, Int, Double, Int, String), loc2 : (CLLocation, Int, Double, Int, String)) -> Bool{
                return (loc1.0.coordinate.latitude - self.main.location!.coordinate.latitude) * (loc1.0.coordinate.latitude - self.main.location!.coordinate.latitude) + (loc1.0.coordinate.longitude - self.main.location!.coordinate.longitude) * (loc1.0.coordinate.longitude - self.main.location!.coordinate.longitude) < (loc2.0.coordinate.latitude - self.main.location!.coordinate.latitude) * (loc2.0.coordinate.latitude - self.main.location!.coordinate.latitude) + (loc2.0.coordinate.longitude - self.main.location!.coordinate.longitude) * (loc2.0.coordinate.longitude - self.main.location!.coordinate.longitude)
            }
            
            locationsToShow = locationsToShow.sort(sortFunc)
        
            let tagSelect = self.storyboard!.instantiateViewControllerWithIdentifier("Group Select") as! TagSelectTableViewController
            NSLog("Size: \(locationsToShow.count)")
            tagSelect.data = locationsToShow
            tagSelect.main = self.main!
            self.navigationController!.showViewController(tagSelect, sender: sender)
            
        } catch let error1 as NSError {
            error = error1
        }
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
        if(annotation is TagAnnotation){
            let tagAnnotation = annotation as! TagAnnotation
            if(tagAnnotation.status != .userAlone){
                if(tagAnnotation.status == .userInRange){
                    pinAnnotationView.rightCalloutAccessoryView = self.createCallOutViewWithButton("I'm Here", width: 64, height: 46, annotation: tagAnnotation, action : "userTaggedLocation:")
                }
                else if(tagAnnotation.status == .userTagged){
                    pinAnnotationView.rightCalloutAccessoryView = self.createCallOutViewWithButton("I'm Leaving", width: 64, height: 46, annotation: tagAnnotation, action : "userLeftLocation:")
                }
                 
                let cavWidth = 115
                let cavHeight = 46
            
                let leftCAV = UIView(frame: CGRect(x: 0, y: 0, width: cavWidth, height: cavHeight))
        
                let xMarg = 4
                let yMarg = 2
                let labelHeight = cavHeight / 2
            
                let label1 = UILabel(frame: CGRect(x: xMarg, y: yMarg, width: cavWidth - xMarg, height: labelHeight))
                label1.text = "Population: \(tagAnnotation.tagInfo.3)"
                label1.adjustsFontSizeToFitWidth = true
        
                let label2 = UILabel(frame: CGRect(x: xMarg, y: cavHeight - labelHeight - yMarg, width: cavWidth -  xMarg, height: labelHeight))
                label2.text = "Age: \(tagAnnotation.tagInfo.1)  \(Int(tagAnnotation.tagInfo.2))% M"
                label2.adjustsFontSizeToFitWidth = true
        
                leftCAV.addSubview(label1)
                leftCAV.addSubview(label2)
                
                pinAnnotationView.leftCalloutAccessoryView = leftCAV
                
            }
            
            pinAnnotationView.draggable = false
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = false
            
            if(tagAnnotation.status == .userAlone||tagAnnotation.status == .userTagged) {
                pinAnnotationView.pinColor = .Purple
            }
            else if (tagAnnotation.status == .userInRange){
                pinAnnotationView.pinColor = .Green
            }
            
        }
        return pinAnnotationView

    }
    
    func createCallOutViewWithButton(title : String, width : Int, height : Int, annotation : MKAnnotation, action : Selector) -> UIView{
        let rightCav = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: width, height: height)
        button.setTitle(title, forState: UIControlState.Normal)
        button.setTitleColor(UIColor.blueColor(), forState: .Normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .Center
        button.addTarget(annotation, action: action, forControlEvents: .TouchUpInside)
        rightCav.addSubview(button)
        return rightCav
    }
    /*
    Sets the address of the subtitle to allow the user to see it, this is done right at the time the user clicks on the annotation because otherwise their will be too many requests to the API
    */
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? TagAnnotation{
            Main.getFormattedAddressFromLocation(annotation.tagInfo.0) { (str: String) -> Void in
                annotation.subtitle = str
            }
        }
    }
    /*
    * Removes the annoying gray bar at the top of the Map, this has no use, so getting rid of it was optimal
    */
    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
}
