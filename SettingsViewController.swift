//
//  SettingsViewController.swift
//  CoreDataTest
//
//  Created by Adam Hodapp on 7/30/15.
//  Copyright (c) 2015 Adam Hodapp. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    var isMale = true

    var main : Main?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.datePickerMode = UIDatePickerMode.Date
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func enter(sender: AnyObject) {
        let x = datePicker.date
        
        NSLog(NSDateFormatter.localizedStringFromDate(x, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        var timeDiffrence = Int(-x.timeIntervalSinceDate(NSDate()) / 31557600)
        
        let male = "m"
        let female = "f"
        let s = self.main?.formatter.stringFromDate(datePicker.date)
        
        let toSend = isMale ? male : female
        NSLog("Date: \(s) Gender \(toSend)")

        main!.birthdayGender = (datePicker.date, toSend)
        
        
        self.navigationController!.popToRootViewControllerAnimated(false)
        
    }
    
    @IBAction func genderFlip(sender: UIButton) {

        if sender == maleButton {
            self.isMale = false
            self.maleButton.hidden = true
            self.femaleButton.hidden = false
        }
        else {
            self.isMale = true
            self.maleButton.hidden = false
            self.femaleButton.hidden = true
        }
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
