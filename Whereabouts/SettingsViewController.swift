
import UIKit
import MessageUI

class SettingsViewController: UITableViewController {

    enum UserSectionRows: Int {
        case UnitStyleRow
        case CloudSyncRow
        case PocketTrackRow
        case TotalRows
    }
    
    enum GeneralSectionRows: Int {
        case RateRow
        case ContactRow
        case TotalRows
    }
    
    enum TableSections: Int {
        case UserSection
        case GeneralSection
        case TotalSections
    }
    
    enum PickerViewControllerTags: Int {
        case AccuracyTag
        case TimeoutTag
        case PhotoRangeTag
        case UnitStyleTag
    }
    
    enum SettingSwitchTag: Int {
        case UnitStyleSwitch
        case CloudSyncSwitch
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
        buildInfoLabel.text = "Whereabouts " + UIDevice.currentDevice().appVersionAndBuildString
        buildInfoLabel.sizeToFit()
        buildInfoLabel.center.x = footerView.center.x
        buildInfoLabel.frame.origin.y = CGRectGetMaxY(logoImageview.bounds) + 20.0
        footerView.addSubview(buildInfoLabel)
        
        return footerView
    }()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"

        tableView = UITableView(frame: CGRect.zero, style: .Grouped)
        tableView.backgroundColor = StyleController.sharedController.backgroundColor
        tableView.tableFooterView = footerView
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .Plain,
            target: self,
            action: #selector(SettingsViewController.doneButtonPressed)
        )
    }
    
    // MARK: - Actions
    func doneButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func switchWasToggled(sender: UISwitch) {
        switch sender.tag {
            
        case SettingSwitchTag.UnitStyleSwitch.rawValue:
            SettingsController.sharedController.isUnitStyleImperial = !sender.on
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
            break
            
        case SettingSwitchTag.CloudSyncSwitch.rawValue:
            SettingsController.sharedController.shouldSyncToCloud = sender.on
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .Automatic)
            break
            
        default:
            break
        }
    }
    
    @objc private func segmentWasChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            SettingsController.sharedController.isUnitStyleImperial = false
        }
        else if sender.selectedSegmentIndex == 1 {
            SettingsController.sharedController.isUnitStyleImperial = true
        }
        else {
            print("WARNING: Failed to handle selected segment index: \(sender.selectedSegmentIndex)")
        }
    }

    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == TableSections.UserSection.rawValue && indexPath.row == UserSectionRows.PocketTrackRow.rawValue {
            return true
        }
        else {
            return false
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.TotalSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.GeneralSection.rawValue {
            return GeneralSectionRows.TotalRows.rawValue
        }
        else if section == TableSections.UserSection.rawValue {
            return UserSectionRows.TotalRows.rawValue
        }
        else {
            return 0
        }
    }

    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "defaultCell")
        
        if indexPath.section == TableSections.UserSection.rawValue {
            switch indexPath.row {
            case UserSectionRows.UnitStyleRow.rawValue:
                let unitSegmentedControl = UISegmentedControl(items: ["Kilometers", "Miles"])
                unitSegmentedControl.selectedSegmentIndex = SettingsController.sharedController.isUnitStyleImperial ? 1 : 0
                unitSegmentedControl.tintColor = StyleController.sharedController.mainTintColor
                unitSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
                unitSegmentedControl.momentary = false
                
                unitSegmentedControl.addTarget(
                    self,
                    action: #selector(SettingsViewController.segmentWasChanged(_:)),
                    forControlEvents: .ValueChanged
                )
                
                cell.addSubview(unitSegmentedControl)
                cell.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-44-[view]-44-|", options: [], metrics: nil, views: ["view": unitSegmentedControl]))
                cell.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[view(<=28)]-|", options: [], metrics: nil, views: ["view": unitSegmentedControl]))
                break
                
            case UserSectionRows.CloudSyncRow.rawValue:
                cell.textLabel?.text = "iCloud Sync"
                
                let unitSwitch = UISwitch()
                unitSwitch.tag = SettingSwitchTag.CloudSyncSwitch.rawValue
                unitSwitch.on = SettingsController.sharedController.shouldSyncToCloud
                unitSwitch.addTarget(
                    self,
                    action: #selector(SettingsViewController.switchWasToggled(_:)),
                    forControlEvents: .ValueChanged
                )
                
                cell.accessoryView = unitSwitch
                break
                
            case UserSectionRows.PocketTrackRow.rawValue:
                cell.textLabel?.text = "Pocket Track"
                cell.detailTextLabel?.text = SettingsController.sharedController.shouldMonitorVisits ? "Enabled" : "Disabled"
                cell.accessoryType = .DisclosureIndicator
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.GeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                cell.textLabel?.text = "Rate Whereabouts"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case GeneralSectionRows.ContactRow.rawValue:
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == TableSections.GeneralSection.rawValue {
            switch indexPath.row {
            case GeneralSectionRows.RateRow.rawValue:
                UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/us/app/whereabouts-location-utility/id931591968?mt=8")!)
                break
                
            case GeneralSectionRows.ContactRow.rawValue:
                let mailVC = MFMailComposeViewController()
                mailVC.setSubject("Whereabouts Feedback")
                mailVC.setToRecipients(["support@ackermann.io"])
                let devInfo = "• iOS Version: \(UIDevice.currentDevice().deviceIOSVersion)<br>• Hardware: \(UIDevice.currentDevice().deviceModel)<br>• App Version: \(UIDevice.currentDevice().appVersionAndBuildString)"
                mailVC.setMessageBody("<br><br><br><br><br><br><br><br><br><br><br><br><hr> <center>Developer Info</center> <br>\(devInfo)<hr>", isHTML: true)
                mailVC.mailComposeDelegate = self
                presentViewController(mailVC, animated: true, completion: nil)
                break
                
            default:
                break
            }
        }
        else if indexPath.section == TableSections.UserSection.rawValue && indexPath.row == UserSectionRows.PocketTrackRow.rawValue {
            let vc = PocketTrackViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
