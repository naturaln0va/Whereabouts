
import UIKit
import MessageUI
import SafariServices

class SettingsViewController: UITableViewController {

    enum UserSectionRows: Int {
        case CloudSyncRow
        case PocketTrackRow
        case TotalRows
    }
    
    enum GeneralSectionRows: Int {
        case RateRow
        case ContactRow
        case TotalRows
    }
    
    enum ExtraSectionRows: Int {
        case Privacy
        case Permissions
        case TotalRows
    }
    
    enum TableSections: Int {
        case UserSection
        case GeneralSection
        case ExtraSection
        case TotalSections
    }
    
    enum SettingSwitchTag: Int {
        case CloudSyncSwitch
    }
    
    private lazy var footerView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(self.view.bounds), height: 130.0))
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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .Plain,
            target: self,
            action: #selector(SettingsViewController.doneButtonPressed)
        )
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if tableView.tableFooterView == nil {
            tableView.tableFooterView = footerView
        }
    }
    
    // MARK: - Actions
    func doneButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func switchWasToggled(sender: UISwitch) {
        switch sender.tag {
            
        case SettingSwitchTag.CloudSyncSwitch.rawValue:
            SettingsController.sharedController.shouldSyncToCloud = sender.on
            
            if sender.on {
                let minutesSinceLastCloudSync = NSDate().minutesSince(SettingsController.sharedController.lastCloudSync)
                if minutesSinceLastCloudSync > 14 {
                    CloudController.sharedController.sync()
                }
            }
            break
            
        default:
            break
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
        else if indexPath.section == TableSections.GeneralSection.rawValue || indexPath.section == TableSections.ExtraSection.rawValue {
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
            var phoneRows = UserSectionRows.TotalRows.rawValue
            
            if UIDevice.currentDevice().isPad {
                phoneRows -= 1
            }
            
            return phoneRows
        }
        else if section == TableSections.ExtraSection.rawValue {
            return ExtraSectionRows.TotalRows.rawValue
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
        else if indexPath.section == TableSections.ExtraSection.rawValue {
            switch indexPath.row {
            case ExtraSectionRows.Privacy.rawValue:
                cell.textLabel?.text = "Privacy"
                cell.accessoryType = .DisclosureIndicator
                break
                
            case ExtraSectionRows.Permissions.rawValue:
                cell.textLabel?.text = "App Permissions"
                cell.accessoryType = .DisclosureIndicator
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
        else if indexPath.section == TableSections.ExtraSection.rawValue {
            switch indexPath.row {
            case ExtraSectionRows.Privacy.rawValue:
                if let url = NSURL(string: "http://www.ackermann.io/privacy") {
                    let safariVC = SFSafariViewController(URL: url)
                    safariVC.view.tintColor = StyleController.sharedController.mainTintColor
                    presentViewController(safariVC, animated: true, completion: nil)
                }
                break
                
            case ExtraSectionRows.Permissions.rawValue:
                if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
                break
                
            default:
                break
            }
        }
    }
    
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
