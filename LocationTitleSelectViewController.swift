//
//  LocationTitleSelectViewController.swift
//  CoreDataTest
//
//  Created by Adam Hodapp on 8/24/15.
//  Copyright (c) 2015 Adam Hodapp. All rights reserved.
//

import UIKit

class LocationTitleSelectViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var addressLabel: UILabel!
    var main : Main?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleField.delegate = self
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createTitle(sender: AnyObject) {
        NSLog(titleField!.text!)
        if main != nil {
            main!.startTaggingLocation(main!.location!, title: self.titleField!.text!)
            main!.mapController.updateLocation(true)
        }
        else{
            NSLog("You stole my cookie!  (main not initialized in LocationTitleSelectViewController)")
        }
        self.navigationController!.popToRootViewControllerAnimated(true)
        
    }

    func textField(textField: UITextField,
        shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {
            
            // Create an `NSCharacterSet` set which includes everything *but* the digits
            let inverseSet = NSCharacterSet(charactersInString:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 @#;'").invertedSet
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            let components = string.componentsSeparatedByCharactersInSet(inverseSet)
            
            // Rejoin these components
            let filtered = components.joinWithSeparator("")
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            return string == filtered
            
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
