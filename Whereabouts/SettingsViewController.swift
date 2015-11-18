
import UIKit

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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        tableView.backgroundColor = ColorController.backgroundColor
    }

    // MARK: - Table view data source
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

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        return cell
    }
    
}
