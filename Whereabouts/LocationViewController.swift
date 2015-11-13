//
//  LocationViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 4/5/15.
//  Copyright (c) 2015 Ryan Ackermann. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class LocationViewController: UIViewController {

    var recent: Recent?
    var mapView: MKMapView!
    let transitionManager = LocationTransitionAnimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MKMapView(frame: view.bounds)
        
        self.transitioningDelegate = self.transitionManager
        
        let coord = CLLocationCoordinate2D(latitude: recent!.placemark.location.coordinate.latitude, longitude: recent!.placemark.location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        let region = MKCoordinateRegion(center: coord, span: span)
        
        mapView.setRegion(region, animated: true)
        view.addSubview(mapView)
        
        let visualEffect = UIBlurEffect(style: .Dark)
        let visualView = UIVisualEffectView(effect: visualEffect)
        visualView.frame = view.bounds
        
        view.addSubview(visualView)
        
        var vibrancyEffect = UIVibrancyEffect(forBlurEffect: visualEffect)
        var vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = view.bounds
        
        var vibrantLabel = UILabel()
        vibrantLabel.text = recent?.longLocationDescription()
        vibrantLabel.font = UIFont(name: "Avenir", size: 42.0)
        vibrantLabel.textAlignment = .Center
        vibrantLabel.lineBreakMode = .ByWordWrapping
        vibrantLabel.numberOfLines = 0
        vibrantLabel.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width - 25.0, height: 176.0)
        vibrantLabel.center = view.center
        
        vibrancyEffectView.contentView.addSubview(vibrantLabel)
        visualView.contentView.addSubview(vibrancyEffectView)
        
        let tap = UITapGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let recent = recent {
            navigationItem.title = recent.placemark.locality
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
