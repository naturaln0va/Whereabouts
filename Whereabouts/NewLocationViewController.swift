
import UIKit
import CoreLocation


class NewLocationViewController: UIViewController
{

    @IBOutlet weak var titleTextView: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var colorSelectorView: UIView!
    
    var location: CLLocation!
    var placemark: CLPlacemark?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "New Location"
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveBarButtonPressed")
        let leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelBarButtonPressed")
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func refreshButtonPressed(sender: AnyObject)
    {
        
    }
    
    func saveBarButtonPressed()
    {
        
    }
    
    func cancelBarButtonPressed()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}


extension NewLocationViewController: UITableViewDelegate, UITableViewDataSource
{
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Latitude"
            cell.detailTextLabel?.text = "\(location.coordinate.latitude)"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "Longitude"
            cell.detailTextLabel?.text = "\(location.coordinate.longitude)"
        } else if indexPath.row == 2 {
            if let placemark = placemark {
                cell.textLabel?.text = "Address"
                cell.detailTextLabel?.text = stringFromAddress(placemark)
            }
            else {
                let formatter = NSDateFormatter()
                formatter.dateStyle = .ShortStyle
                
                cell.textLabel?.text = "Date"
                cell.detailTextLabel?.text = formatter.stringFromDate(location.timestamp)
            }
        } else if indexPath.row == 3 {
            if let _ = placemark {
                let formatter = NSDateFormatter()
                formatter.dateStyle = .ShortStyle
                
                cell.textLabel?.text = "Date"
                cell.detailTextLabel?.text = formatter.stringFromDate(location.timestamp)
            }
        }
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let _ = placemark {
            return 4
        }
        else {
            return 3
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return false
    }
    
}
