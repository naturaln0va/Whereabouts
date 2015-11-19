
import UIKit
import MessageUI

enum GeneralSectionRows: Int
{
    case kRateRow
    case kContactRow
    case kTotalRows
}

enum UserSectionRows: Int
{
    case kAccuracyRow
    case kTimeoutRow
    case kPhotoRangeRow
    case kUnitStyleRow
    case kTotalRows
}

enum TableSections: Int
{
    case kGeneralSection
    case kUserSection
    case kTotalSections
}


class SettingsViewController: UITableViewController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Settings"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        tableView.backgroundColor = ColorController.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneButtonPressed")
    }
    
    // MARK: - Actions
    func doneButtonPressed()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 24
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let coloredBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: CGRectGetWidth(tableView.bounds), height: 22))
        coloredBackgroundView.backgroundColor = UIColor.clearColor()
        return coloredBackgroundView
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return TableSections.kTotalSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == TableSections.kGeneralSection.rawValue {
            return GeneralSectionRows.kTotalRows.rawValue
        }
        else if section == TableSections.kUserSection.rawValue {
            return UserSectionRows.kTotalRows.rawValue
        }
        else {
            return 0
        }
    }

    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = StyledCell(style: .Subtitle, reuseIdentifier: "defaultCell")
        
        if indexPath.section == TableSections.kGeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.kRateRow.rawValue:
                cell.textLabel?.text = "Rate Whereabouts"
                cell.imageView?.contentMode = .ScaleAspectFit
                cell.imageView?.image = UIImage(named: "rate-star")
                break
                
            case GeneralSectionRows.kContactRow.rawValue:
                cell.textLabel?.text = "Contact the Developer"
                cell.userInteractionEnabled = MFMailComposeViewController.canSendMail()
                cell.textLabel?.enabled = MFMailComposeViewController.canSendMail()
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.kUserSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.kAccuracyRow.rawValue:
                cell.textLabel?.text = "Location Accuracy"
                break
                
            case UserSectionRows.kTimeoutRow.rawValue:
                cell.textLabel?.text = "Location Timeout"
                break
                
            case UserSectionRows.kPhotoRangeRow.rawValue:
                cell.textLabel?.text = "Nearby Photo Range"
                break
                
            case UserSectionRows.kUnitStyleRow.rawValue:
                cell.textLabel?.text = "Unit Style"
                break
                
            default:
                break
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == TableSections.kGeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.kRateRow.rawValue:
                UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/us/app/whereabouts-location-utility/id931591968?mt=8")!)
                break
                
            case GeneralSectionRows.kContactRow.rawValue:
                let mailVC = MFMailComposeViewController()
                mailVC.setSubject("Whereabouts Feedback")
                mailVC.setToRecipients(["support@ackermann.io"])
                let devInfo = "• iOS Version: \(UIDevice.currentDevice().deviceIOSVersion)<br>• Hardware: \(UIDevice.currentDevice().deviceModel)"
                mailVC.setMessageBody("<br><br><br><br><br><br><br><br><br><br><br><br><hr> <center>Developer Info</center> <br>\(devInfo)<hr>", isHTML: true)
                mailVC.mailComposeDelegate = self
                presentViewController(mailVC, animated: true, completion: nil)
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.kUserSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.kAccuracyRow.rawValue:
                break
                
            case UserSectionRows.kTimeoutRow.rawValue:
                break
                
            case UserSectionRows.kPhotoRangeRow.rawValue:
                break
                
            case UserSectionRows.kUnitStyleRow.rawValue:
                break
                
            default:
                break
            }
        }
    }
    
}


extension SettingsViewController: MFMailComposeViewControllerDelegate
{
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
