
import UIKit
import CoreLocation

class TagSelectTableViewController: UITableViewController {
    
    /*
    BUG:  Table will load with no strings showing up after it is exited once
    Notes:  Only happens once the user has used the "Show on Map" button
    Resolved:  "Show on Map" button function modified to pop to root view controller WITHOUT animation, so this view is bi-passed
    */
    // Latitude, longitude, Average age, percentMale, population, title
    var data = [(CLLocation, Int, Double, Int, String)]()
    var main : Main?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController!.setToolbarHidden(false, animated: false)
    }

    override func viewWillDisappear(animated: Bool){
        self.navigationController!.setToolbarHidden(true, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    This is called only when the bottom left bar button item is pressed.  Navigation controller pops to root View,
    which is the MapController
    Implemented programatically because the storyboard "push" funciton created a new MapView
    */
    @IBAction func returnToMapView(sender: UIBarButtonItem) {
        self.navigationController!.popToRootViewControllerAnimated(false)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return data.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell?
        if let cellAttempt = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier"){
            cell = cellAttempt
        }
        else{
            cell = UITableViewCell(style: UITableViewCellStyle.Default , reuseIdentifier: "reuseIdentifier")
            cell!.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
        }
        // Idea: App that you take a picture of something once a week and then it makes a timeline
        
        cell!.textLabel!.text = self.data[indexPath.row].4
        cell!.selectionStyle = UITableViewCellSelectionStyle.Blue

        return cell!
    }
    /*
    Loads a new view describing the tag after the user selects a row on the path
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tagInfo = self.storyboard!.instantiateViewControllerWithIdentifier("DetailedTagInfo") as! TagDetailViewController
        tagInfo.setTag(data[indexPath.row])
        tagInfo.main = self.main
        self.navigationController!.showViewController(tagInfo, sender: tableView)
    }
    /*
    Action function for the plus button on the screen of the view, used to open the tag creation window
    */
    @IBAction func add(sender: UIBarButtonItem) {
        let titleSelect = self.storyboard!.instantiateViewControllerWithIdentifier("Title Select") as! LocationTitleSelectViewController
        titleSelect.main = self.main!
        Main.getFormattedAddressFromLocation(main!.location!){ (str: String) -> Void in
            titleSelect.addressLabel.text = str
        }
        self.navigationController!.showViewController(titleSelect, sender: sender)
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
