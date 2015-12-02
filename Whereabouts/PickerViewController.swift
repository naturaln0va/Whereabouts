
import UIKit

struct PickerData
{
    var currentIndex: Int
    var values: Array<AnyObject>
    var labels: Array<String>
    var detailLabels: Array<String>?
    var footerDescription: String?
    var count: Int {
        get {
            return values.count
        }
    }
    
    init(values: Array<AnyObject>, currentIndex: Int, labels: Array<String>, detailLabels: Array<String>? = nil, footerDescription: String? = nil)
    {
        self.values = values
        self.currentIndex = currentIndex
        self.labels = labels
        self.detailLabels = detailLabels ?? nil
        self.footerDescription = footerDescription ?? nil
    }
}

protocol PickerViewControllerDelegate
{
    func pickerViewController(pvc: PickerViewController, didPickObject object: AnyObject)
}


class PickerViewController: UITableViewController
{
    
    var dataForPicker: PickerData?
    var delegate: PickerViewControllerDelegate?
    var tag: Int!
    
    
    init(data: PickerData, tag: Int, title: String)
    {
        super.init(style: .Plain)
        dataForPicker = data
        self.tag = tag
        self.title = title
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        tableView.backgroundColor = ColorController.backgroundColor
        
        if data.footerDescription != nil {
            let footerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(tableView.bounds), height: 64.0))
            footerView.backgroundColor = UIColor.clearColor()
            
            let descriptionLabel = UILabel()
            descriptionLabel.numberOfLines = 0
            descriptionLabel.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightLight)
            descriptionLabel.text = data.footerDescription!
            descriptionLabel.bounds = footerView.bounds
            descriptionLabel.center = footerView.center
            descriptionLabel.frame.origin.x += 15.0
            footerView.addSubview(descriptionLabel)
            
            tableView.tableFooterView = footerView
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 24.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let coloredBackgroundView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(tableView.bounds), height: 24.0))
        coloredBackgroundView.backgroundColor = UIColor.clearColor()
        return coloredBackgroundView
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        return data.count
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = StyledCell(style: .Subtitle, reuseIdentifier: "defaultCell")
        
        guard let data = dataForPicker else { fatalError("There was no data") }

        cell.textLabel?.text = data.labels[indexPath.row]
        
        if let detailLabels = data.detailLabels {
            cell.detailTextLabel?.text = detailLabels[indexPath.row]
        }
        
        if data.currentIndex == indexPath.row {
            cell.tintColor = ColorController.navBarBackgroundColor
            cell.accessoryType = .Checkmark
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let data = dataForPicker else { fatalError("There was no data") }
        
        if let delegate = delegate {
            delegate.pickerViewController(self, didPickObject: data.values[indexPath.row])
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
}
