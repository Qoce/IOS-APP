//  TagDetailViewController.swift
//  CoreDataTest
//
//  Created by Adam Hodapp on 12/8/15.
//  Copyright © 2015 Adam Hodapp. All rights reserved.
//

import UIKit
import MapKit

class TagDetailViewController: UIViewController {
    
    var tag : (CLLocation, Int, Double, Int, String)?
    var main : Main?
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var population: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var gender: UILabel!
    @IBOutlet weak var age: UILabel!
    
    /*
    * Temporarily stored values of string that are used to set the titles of each label in the refresh function
    */
    var nameStr : String!
    var populationStr : String!
    var ageStr : String!
    var genderStr : String!
    var addressStr : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        refresh()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //Sets the tag variable, which is directly related to the display of the informational labels
    func setTag(tag : (CLLocation, Int, Double, Int, String)){
        self.tag = tag
        self.nameStr = tag.4
        self.populationStr = "Population: \(tag.3)"
        self.ageStr = "Average Age: \(tag.1)"
        if tag.2 > 50 {
            self.genderStr = "\(tag.2)% Male"
        }
        else{
             self.genderStr = "\(100 - tag.2)% Female"
        }
        Main.getFormattedAddressFromLocation(tag.0) { (str : String) -> Void in
            self.addressStr = str
            self.refresh() //Called because this function might not be called immeditally, so this prevents the adress string from being neglected
        }
    }
    func setMain_(main: Main){
        self.main = main
    }
    //Returns true if the tag is initizlized, to indicate that the view and its components should work as expected
    func isValid() -> Bool{
        if(self.tag != nil || self.main == nil){
            return true
        }
        return false
    }
    @IBAction func userTaggedLocation(sender: AnyObject) {
        main!.startTaggingLocation(tag!.0, title: tag!.4)
        main!.mapController.updateLocation(false)
        showOnMap(sender)
    }
    @IBAction func showOnMap(sender: AnyObject) {
        main!.mapController.zoomToLocation(self.tag!.0)
        self.navigationController!.setNavigationBarHidden(true, animated: false)// This line may be unimportant...
        self.navigationController!.popToRootViewControllerAnimated(false)
        main!.mapController.updateLocation(true)
    }
    
    /*
    This function exists to set the strings of the labels after the view is opened, because if it is set during the view did load function the labels will not be initialized yet.
    */
    func refresh(){
        name.text = nameStr
        population.text = populationStr
        gender.text = genderStr
        age.text = ageStr
        address.text = addressStr
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
