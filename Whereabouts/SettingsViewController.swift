
import UIKit
import MessageUI


class SettingsViewController: UITableViewController
{

    enum UserSectionRows: Int
    {
        case kAccuracyRow
        case kTimeoutRow
        case kPhotoRangeRow
        case kUnitStyleRow
        case kTotalRows
    }
    
    enum GeneralSectionRows: Int
    {
        case kRateRow
        case kContactRow
        case kTotalRows
    }
    
    enum TableSections: Int
    {
        case kUserSection
        case kGeneralSection
        case kTotalSections
    }
    
    enum PickerViewControllerTags: Int
    {
        case AccuracyTag
        case TimeoutTag
        case PhotoRangeTag
        case UnitStyleTag
    }
    
    private lazy var footerView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(UIScreen.mainScreen().bounds), height: 130.0))
        footerView.backgroundColor = UIColor.clearColor()
        
        let logoImageview = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0))
        logoImageview.image = UIImage(named: "desaturated-flat-logo")
        logoImageview.contentMode = .ScaleAspectFit
        logoImageview.center = footerView.center
        logoImageview.frame.origin.y -= 12.0
        logoImageview.alpha = 0.75
        footerView.addSubview(logoImageview)
        
        let buildInfoLabel = UILabel()
        buildInfoLabel.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightLight)
        let identifer = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
        buildInfoLabel.text = "Whereabouts \(identifer).\(build)"
        buildInfoLabel.sizeToFit()
        buildInfoLabel.center.x = footerView.center.x
        buildInfoLabel.frame.origin.y = CGRectGetMaxY(logoImageview.bounds) + 20.0
        footerView.addSubview(buildInfoLabel)
        
        return footerView
    }()
    
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Settings"

        tableView = UITableView(frame: view.bounds, style: .Grouped)
        tableView.backgroundColor = ColorController.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "doneButtonPressed")
        
        tableView.tableFooterView = footerView
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsDidChange", name: kSettingsControllerDidChangeNotification, object: nil)
    }
    
    // MARK: - Actions
    func doneButtonPressed()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Notifications
    func settingsDidChange()
    {
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 35.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let coloredBackgroundView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(tableView.bounds), height: 24.0))
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
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "defaultCell")
        
        if indexPath.section == TableSections.kUserSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.kAccuracyRow.rawValue:
                cell.textLabel?.text = "Location Accuracy"
                cell.detailTextLabel?.text = SettingsController.sharedController.stringForDistanceAccuracy()
                cell.accessoryType = .DisclosureIndicator
                break
                
            case UserSectionRows.kTimeoutRow.rawValue:
                cell.textLabel?.text = "Location Timeout"
                cell.detailTextLabel?.text = "\(SettingsController.sharedController.locationTimeout)s"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case UserSectionRows.kPhotoRangeRow.rawValue:
                cell.textLabel?.text = "Nearby Photo Range"
                cell.detailTextLabel?.text = SettingsController.sharedController.stringForPhotoRange()
                cell.accessoryType = .DisclosureIndicator
                break
                
            case UserSectionRows.kUnitStyleRow.rawValue:
                cell.textLabel?.text = "Unit Style"
                cell.detailTextLabel?.text = SettingsController.sharedController.isUnitStyleImperial ? "Customary" : "Metric"
                cell.accessoryType = .DisclosureIndicator
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.kGeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.kRateRow.rawValue:
                cell.textLabel?.text = "Rate Whereabouts"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case GeneralSectionRows.kContactRow.rawValue:
                cell.textLabel?.text = "Contact the Developer"
                cell.accessoryType = .DisclosureIndicator
                cell.userInteractionEnabled = MFMailComposeViewController.canSendMail()
                cell.textLabel?.enabled = MFMailComposeViewController.canSendMail()
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
                let identifer = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
                let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
                let devInfo = "• iOS Version: \(UIDevice.currentDevice().deviceIOSVersion)<br>• Hardware: \(UIDevice.currentDevice().deviceModel)<br>• App Version: \(identifer).\(build)"
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
                let values = [
                    kHorizontalAccuracyPoor,
                    kHorizontalAccuracyFair,
                    kHorizontalAccuracyAverage,
                    kHorizontalAccuracyGood,
                    kHorizontalAccuracyBest
                ]
                let labels = [
                    "Poor",
                    "Fair",
                    "Average",
                    "Good",
                    "Best"
                ]
                
                let index: Int = values.indexOf(SettingsController.sharedController.distanceAccuracy)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: nil, footerDescription: "Higher accuracy may take longer when locating.")
                let pvc = PickerViewController(data: data, tag: PickerViewControllerTags.AccuracyTag.rawValue, title: "Accuracy")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            case UserSectionRows.kTimeoutRow.rawValue:
                let values = [
                    kLocationTimeoutShort,
                    kLocationTimeoutNormal,
                    kLocationTimeoutLong,
                    kLocationTimeoutVeryLong
                ]
                let labels = [
                    "Short",
                    "Normal",
                    "Long",
                    "Very Long"
                ]
                let details = [
                    "10s",
                    "15s",
                    "25s",
                    "45s"
                ]
                
                let index: Int = values.indexOf(SettingsController.sharedController.locationTimeout)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: details, footerDescription: "When attempting to find your location a longer timeout may increase accuracy.")
                let pvc = PickerViewController(data: data, tag: PickerViewControllerTags.TimeoutTag.rawValue, title: "Timeout")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            case UserSectionRows.kPhotoRangeRow.rawValue:
                let values = [
                    50,
                    250,
                    1600,
                    5000
                ]
                let labels = [
                    "Low",
                    "Normal",
                    "High",
                    "Very High"
                ]
                
                var details = Array<String>()
                if SettingsController.sharedController.isUnitStyleImperial {
                    details = [
                        "165 feet",
                        "825 feet",
                        "1 mile",
                        "3 miles"
                    ]
                }
                else {
                    details = [
                        "50 meters",
                        "250 meters",
                        "1.6 kilometers",
                        "5 kilometers"
                    ]
                }
                
                let index: Int = values.indexOf(SettingsController.sharedController.nearbyPhotoRange)!
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: details, footerDescription: "You can see photos you have taken near a saved location.")
                let pvc = PickerViewController(data: data, tag: PickerViewControllerTags.PhotoRangeTag.rawValue, title: "Range")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
                break
                
            case UserSectionRows.kUnitStyleRow.rawValue:
                let values = [
                    true,
                    false
                ]
                let labels = [
                    "Imperial",
                    "Metric"
                ]
                
                let index: Int = SettingsController.sharedController.isUnitStyleImperial ? 0 : 1
                
                let data = PickerData(values: values, currentIndex: index, labels: labels, detailLabels: nil, footerDescription: "Customary: Miles, Feet\nMetric: Kilometers, Meters")
                let pvc = PickerViewController(data: data, tag: PickerViewControllerTags.UnitStyleTag.rawValue, title: "Unit")
                pvc.delegate = self
                
                navigationController?.pushViewController(pvc, animated: true)
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


extension SettingsViewController: PickerViewControllerDelegate
{
    
    func pickerViewController(pvc: PickerViewController, didPickObject object: AnyObject)
    {
        switch pvc.tag {
            
        case PickerViewControllerTags.AccuracyTag.rawValue:
            SettingsController.sharedController.distanceAccuracy = object as! Double
            break
            
        case PickerViewControllerTags.TimeoutTag.rawValue:
            SettingsController.sharedController.locationTimeout = object as! Int
            break
            
        case PickerViewControllerTags.PhotoRangeTag.rawValue:
            SettingsController.sharedController.nearbyPhotoRange = object as! Int
            break
            
        case PickerViewControllerTags.UnitStyleTag.rawValue:
            SettingsController.sharedController.isUnitStyleImperial = object as! Bool
            break
            
        default:
            break
            
        }
    }
    
}
