
import UIKit
import CoreData
import CoreLocation
import MapKit

class LocationsViewController: UIViewController {
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)
        label.textAlignment = .Center
        label.text = CloudController.sharedController.syncing ? "Syncing with iCloud" : ""
        label.sizeToFit()
        return label
    }()
    
    private lazy var titleToggle: UISegmentedControl = {
        let control = UISegmentedControl(items: ["List", "Map"])
        control.selectedSegmentIndex = 0
        control.tintColor = StyleController.sharedController.navBarTintColor
        control.frame.size.width = 150.0
        control.addTarget(self, action: #selector(LocationsViewController.toggleWasChanged), forControlEvents: .ValueChanged)
        return control
    }()
    
    private lazy var messageBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: self.messageLabel)
    private lazy var spaceBarButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    private lazy var editBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(LocationsViewController.editButtonPressed))
    private lazy var doneBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(LocationsViewController.doneButtonPressed))
    
    private let listViewController = ListViewController()
    private let mapViewController = MapViewController()
    
    private enum ToggleIndex: Int {
        case List
        case Map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Whereabouts"
        view.backgroundColor = StyleController.sharedController.backgroundColor
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(LocationsViewController.locateBarButtonWasPressed))
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings-gear"), style: .Plain, target: self, action: #selector(LocationsViewController.settingsBarButtonWasPressed))
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        navigationItem.titleView = titleToggle
        
        navigationController?.toolbarHidden = false
        toolbarItems = [editBarButton, spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem]
        
        CloudController.sharedController.getChanges()
        
        beginObserving()
        refreshToggleState()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        print("title segment height: \(titleToggle.frame.height)")
    }
    
    // MARK: - Helpers
    func beginObserving() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(LocationsViewController.cloudSyncComplete),
            name: CloudController.kSyncCompleteNotificationKey,
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(LocationsViewController.cloudSyncComplete),
            name: CloudController.kCloudErrorNotificationKey,
            object: nil
        )
    }
    
    private func updateMessageLabel(updatedText: String?) {
        messageLabel.text = updatedText ?? ""
        messageLabel.sizeToFit()
    }
    
    private func refreshToggleState() {
        guard let tab = ToggleIndex(rawValue: titleToggle.selectedSegmentIndex) else {
            return
        }
        
        refreshToolbarForToggleState(tab)
        
        if tab == .List {
            removeMapChildVC()
            addListChildVC()
        }
        else {
            removeListChildVC()
            addMapChildVC()
        }
    }
    
    private func refreshToolbarForToggleState(tab: ToggleIndex) {
        if tab == .List {
            if listViewController.tableView.editing {
                toolbarItems = [doneBarButton, spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem]
            }
            else {
                toolbarItems = [editBarButton, spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem]
            }
        }
        else {
            toolbarItems = [MKUserTrackingBarButtonItem(mapView: mapViewController.mapView) ,spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem]
        }
    }
    
    // MARK: - ViewController Containment Managment
    private func wrappedAddChildVC(vc: UIViewController) {
        if vc.view.isDescendantOfView(view) {
            return
        }
        
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(vc)
        view.addSubview(vc.view)
        
        let views = ["view": vc.view]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views))
        vc.didMoveToParentViewController(self)
    }
    
    private func wrappedRemoveChildVC(vc: UIViewController) {
        if !vc.isViewLoaded() {
            return
        }
        
        vc.willMoveToParentViewController(nil)
        vc.view.removeFromSuperview()
        vc.removeFromParentViewController()
    }
    
    private func addListChildVC() {
        wrappedAddChildVC(listViewController)
    }
    
    private func removeListChildVC() {
        wrappedRemoveChildVC(listViewController)
    }
    
    private func addMapChildVC() {
        wrappedAddChildVC(mapViewController)
    }
    
    private func removeMapChildVC() {
        wrappedRemoveChildVC(mapViewController)
    }
    
    // MARK: - Actions
    internal func locateBarButtonWasPressed() {
        presentViewController(StyledNavigationController(rootViewController: AddViewController()), animated: true, completion: nil)
    }
    
    internal func settingsBarButtonWasPressed() {
        presentViewController(StyledNavigationController(rootViewController: SettingsViewController()), animated: true, completion: nil)
    }
    
    internal func editButtonPressed() {
        listViewController.tableView.setEditing(true, animated: true)
        toolbarItems = [doneBarButton, spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem]
    }
    
    internal func doneButtonPressed() {
        listViewController.tableView.setEditing(false, animated: true)
        toolbarItems = [editBarButton, spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem]
    }
    
    internal func toggleWasChanged() {
        refreshToggleState()
    }
    
    // MARK: - Notifications
    internal func cloudSyncComplete() {
        updateMessageLabel(nil)
    }
    
    internal func cloudErrorOccurred() {
        updateMessageLabel("An error occurred")
    }
    
}
