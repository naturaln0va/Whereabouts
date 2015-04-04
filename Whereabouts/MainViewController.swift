//
//  ViewController.swift
//  Whereabouts
//
//  Created by Ryan Ackermann on 10/20/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

import UIKit
import QuartzCore
import MapKit
import CoreLocation
import AudioToolbox

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // UI Variables
    var locationLabel: UILabel!
    var compassView: UIImageView!
    var bouncyAlertView: UIView!
    var alertLabel: UILabel!
    var saveButton: UIButton!
    var shareButton: UIButton!
    var relocateButton: UIButton!
    var updatedDisplayView: UIView!
    var updatedLabel: UILabel!
    var cityDisplay: UIView!
    var cityLabel: UILabel!
    var mapView: MKMapView!
    var placemarkInfoLabel: UILabel!
    var latLongLabel: UILabel!
    
    // Sizes
    let alertViewSize: CGFloat = 265.0
    let alertLabelSize: CGFloat = 240.0
    
    // Gesture Recognizers
    var dismissRecognizer: UITapGestureRecognizer!
    
    // Fancy Effect Variables
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    let blurVibrancy = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark)))
    
    // Core Location Variales
    let locationManager = CLLocationManager()
    var location: CLLocation!
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    
    // Foundational Variables
    var lastGeocodingError: NSError?
    var timer: NSTimer?
    let colorFadeTime: NSTimeInterval = 0.65
    var lastLocationError: NSError?
    
    // Conditionals
    var hidden: Bool = false
    var holding: Bool = false
    var performingReversGeocoding: Bool = false
    var updatingLocation: Bool = false
    var showingVerbose: Bool = false
    var showingInformation: Bool = false
    
    // Core Animation Variables
    let gradient: CAGradientLayer = CAGradientLayer()
    let touchHoldLayer = CAShapeLayer()
    let textAnimation = CATransition()
    
    // Sound ID's
    var tapAudioEffect: SystemSoundID = 0
    //var locationAudioEffect: SystemSoundID = 0
    
    // Gradient Arrays
    let darkColors = [UIColor(hex: 0x34495e).CGColor, UIColor(hex: 0x2c3e50).CGColor]
    let greenColors = [UIColor(hex: 0x2ecc71).CGColor, UIColor(hex: 0x27ae60).CGColor]
    let redColors = [UIColor(hex: 0xe74c3c).CGColor, UIColor(hex: 0xc0392b).CGColor]
    let yellowColors = [UIColor(hex: 0xf1c40f).CGColor, UIColor(hex: 0xf39c12).CGColor]
    let blueColors = [UIColor(hex: 0x00b9ff).CGColor, UIColor(hex: 0x007aff).CGColor]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clearColor()
        showingInformation = false
        
        initUIElements()
        initSounds()
        updateLabel()
        
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.00725, longitudeDelta: 0.00725))
        mapView.setRegion(region, animated: true)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if defaults.objectForKey("firstLaunch") as? String == "true" {
            
            showBouncyAlert("Thanks for purchasing! ❤️")
            
            defaults.setObject("true", forKey: "firstLaunch")
            
            defaults.synchronize()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        location = nil
        lastLocationError = nil
        placemark = nil
        lastGeocodingError = nil
        updateLabel()
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if flag {
            holding = false
            touchHoldLayer.fillColor = UIColor.whiteColor().CGColor
            getLocation()
            rotateCompass()
        }
    }
    
    //MARK: - Init Methods
    
    func initSounds() {
        var tapSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Satisfying Click", ofType: "wav")!)
        //var locationSoundPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Satisfying Click", ofType: "wav")!)
        
        AudioServicesCreateSystemSoundID(tapSoundPath! as CFURLRef, &tapAudioEffect)
        //AudioServicesCreateSystemSoundID(locationSoundPath! as CFURLRef, &locationAudioEffect)
    }
    
    func initUIElements() {
        var compassImage: UIImage = UIImage()
        var anchorPointForCompass: CGPoint
        
        if UIScreen.mainScreen().nativeBounds.width <= 750 {
            compassImage = resizeImage(UIImage(named: "CompassFor6")!, byFactor: 0.72)
            anchorPointForCompass = CGPointMake(0.5, 0.53)
        } else {
            compassImage = UIImage(named: "CompassFor6+")!
            anchorPointForCompass = CGPointMake(0.5, 0.56)
        }
        
        let imageWidth = compassImage.size.width
        let imageHeight = compassImage.size.height
        let compassSize: CGFloat = max(imageWidth, imageHeight)
        let labelSize: CGFloat = 220.0
        
        compassView = UIImageView(image: compassImage)
        compassView.layer.anchorPoint = anchorPointForCompass
        compassView.contentMode = .ScaleAspectFill
        compassView.frame = CGRectMake(CGRectGetMidX(view.frame) - compassSize / 2, CGRectGetMidY(view.frame) - compassSize / 2, compassSize, compassSize)
        view.addSubview(compassView)
        
        locationLabel = UILabel(frame: CGRectMake((view.frame.size.width/2) - (labelSize/2), (view.frame.size.height/2) - (labelSize/2) + 14, labelSize, labelSize))
        locationLabel.font = UIFont(name: "Berlin", size: 27.0)
        locationLabel.numberOfLines = 0
        locationLabel.lineBreakMode = .ByWordWrapping
        locationLabel.textAlignment = .Center
        locationLabel.textColor = UIColor.whiteColor()
        view.addSubview(locationLabel)
        
        touchHoldLayer.path = UIBezierPath(ovalInRect: CGRect(x: 15, y: 15, width: 110, height: 110)).CGPath
        touchHoldLayer.lineWidth = 4.0
        touchHoldLayer.lineCap = kCALineCapRound
        touchHoldLayer.strokeColor = UIColor.whiteColor().CGColor
        touchHoldLayer.fillColor = UIColor.clearColor().CGColor
        touchHoldLayer.strokeEnd = 0.0
        view.layer.addSublayer(touchHoldLayer)
        
        bouncyAlertView = UIView(frame: CGRectMake((self.view.frame.width / 2) - (alertViewSize / 2), (self.view.frame.height / 2) - (alertViewSize / 2), alertViewSize, alertViewSize))
        bouncyAlertView.bounds = CGRect(origin: bouncyAlertView.bounds.origin, size: CGSizeZero)
        bouncyAlertView.layer.cornerRadius = 12.0
        bouncyAlertView.layer.masksToBounds = true
        bouncyAlertView.backgroundColor = UIColor(hex: 0x242424, alpha: 1.0)
        view.addSubview(bouncyAlertView)
        
        dismissRecognizer = UITapGestureRecognizer(target: self, action: "dismiss:")
        bouncyAlertView.addGestureRecognizer(dismissRecognizer)
        
        alertLabel = UILabel(frame: CGRectMake((alertViewSize / 2) - (alertLabelSize / 2), (alertViewSize / 2) - (alertLabelSize / 2), alertLabelSize, alertLabelSize))
        alertLabel.bounds = CGRect(origin: alertLabel.bounds.origin, size: CGSizeZero)
        alertLabel.font = UIFont(name: "Berlin", size: 30.0)
        alertLabel.numberOfLines = 0
        alertLabel.lineBreakMode = .ByWordWrapping
        alertLabel.textAlignment = .Center
        alertLabel.textColor = UIColor.whiteColor()
        bouncyAlertView.addSubview(alertLabel)
        
        //Buttons
        
        let numButtons: UInt = 3
        let deviceWidth: Float = Float(CGRectGetWidth(self.view.frame))
        // 17% space
        var buttonSize: Float = (deviceWidth / Float(numButtons)) - (deviceWidth * 0.07)
        //(320-(74*4))/4
        var space: Float = (deviceWidth - (Float(numButtons) * buttonSize)) / (Float(numButtons) + 1)
        println("Size of buttons: \(buttonSize), with space of \(space), for width of \(deviceWidth)")
        
        saveButton = UIButton(frame: CGRect(x: Int(space), y: Int((Int(CGRectGetMaxY(self.view.frame)) - Int(buttonSize)) - Int(space)), width: Int(buttonSize), height: Int(buttonSize)))
        saveButton.setBackgroundImage(UIImage(named: "Save-Button"), forState: .Normal)
        saveButton.setBackgroundImage(UIImage(named: "Save-Pressed"), forState: .Highlighted)
        saveButton.addTarget(self, action: Selector("saveAction:"), forControlEvents: .TouchDown)
        saveButton.alpha = 0.0
        view.addSubview(saveButton)
        
        shareButton = UIButton(frame: CGRect(x: Int((Int(space)*2)+Int(buttonSize)), y: Int((Int(CGRectGetMaxY(self.view.frame)) - Int(buttonSize)) - Int(space)), width: Int(buttonSize), height: Int(buttonSize)))
        shareButton.setBackgroundImage(UIImage(named: "Share-Button"), forState: .Normal)
        shareButton.setBackgroundImage(UIImage(named: "Share-Pressed"), forState: .Highlighted)
        shareButton.addTarget(self, action: Selector("shareAction:"), forControlEvents: .TouchDown)
        shareButton.alpha = 0.0
        view.addSubview(shareButton)
        
        relocateButton = UIButton(frame: CGRect(x: Int((Int(space)*3)+(Int(buttonSize)*2)), y: Int((Int(CGRectGetMaxY(self.view.frame)) - Int(buttonSize)) - Int(space)), width: Int(buttonSize), height: Int(buttonSize)))
        relocateButton.setBackgroundImage(UIImage(named: "Relocate-Button"), forState: .Normal)
        relocateButton.setBackgroundImage(UIImage(named: "Relocate-Pressed"), forState: .Highlighted)
        relocateButton.addTarget(self, action: Selector("relocateAction:"), forControlEvents: .TouchDown)
        relocateButton.alpha = 0.0
        view.addSubview(relocateButton)
        
        //City Display
        
        cityDisplay = UIView(frame: CGRect(x: 0, y: -100, width: CGRectGetWidth(self.view.bounds), height: 70))
        view.addSubview(cityDisplay)
        
        cityLabel = UILabel(frame: CGRect(x: CGRectGetMidX(cityDisplay.bounds) - (350 / 2), y: CGRectGetMidY(cityDisplay.bounds) - (42 / 2), width: 350, height: 54))
        cityLabel.font = UIFont(name: "Berlin", size: 32.0)
        cityLabel.numberOfLines = 0
        cityLabel.lineBreakMode = .ByWordWrapping
        cityLabel.textAlignment = .Center
        cityLabel.textColor = UIColor.whiteColor()
        cityDisplay.addSubview(cityLabel)
        cityLabel.text = "Silverton"
        
        //Map View
        
        if RADevice.getDeviceName() == "iPhone4" {
            mapView = MKMapView(frame: CGRect(x: 0, y: CGRectGetHeight(cityDisplay.bounds), width: CGRectGetWidth(self.view.bounds), height: 140))
        } else if RADevice.getDeviceName() == "iPhone6+" {
            mapView = MKMapView(frame: CGRect(x: 0, y: CGRectGetHeight(cityDisplay.bounds), width: CGRectGetWidth(self.view.bounds), height: 280))
        }else {
            mapView = MKMapView(frame: CGRect(x: 0, y: CGRectGetHeight(cityDisplay.bounds), width: CGRectGetWidth(self.view.bounds), height: 180))
        }
        mapView.alpha = 0.0
        mapView.delegate = self
        self.view.addSubview(mapView)
        
        //Location Info
        
        if RADevice.getDeviceName() == "iPhone4" {
            placemarkInfoLabel = UILabel(frame: CGRect(x: 10, y: CGFloat((CGRectGetHeight(self.view.frame) + 300)), width: CGRectGetWidth(self.view.bounds) - 20, height: 105))
        } else {
            placemarkInfoLabel = UILabel(frame: CGRect(x: 10, y: CGFloat((CGRectGetHeight(self.view.frame) + 300)), width: CGRectGetWidth(self.view.bounds) - 20, height: 165))
        }
        placemarkInfoLabel.font = UIFont(name: "Berlin", size: 42.0)
        placemarkInfoLabel.numberOfLines = 0
        placemarkInfoLabel.lineBreakMode = .ByWordWrapping
        placemarkInfoLabel.textAlignment = .Left
        placemarkInfoLabel.textColor = UIColor.whiteColor()
        view.addSubview(placemarkInfoLabel)
        bottomBorderForView(placemarkInfoLabel)
        placemarkInfoLabel.text = ""
        
        latLongLabel = UILabel(frame: CGRect(x: 10, y: CGRectGetHeight(cityDisplay.bounds) + CGRectGetHeight(mapView.bounds) + CGRectGetHeight(placemarkInfoLabel.bounds), width: CGRectGetWidth(self.view.bounds) - 20, height: 50))
        var fontSize = CGFloat(0.0)
        if RADevice.getDeviceName() != "iPhone6" || RADevice.getDeviceName() != "iPhone6+" {
            fontSize = 24.0
        } else {
            fontSize = 44.0
        }
        latLongLabel.font = UIFont(name: "Berlin", size: fontSize)
        latLongLabel.numberOfLines = 0
        latLongLabel.lineBreakMode = .ByWordWrapping
        latLongLabel.textAlignment = .Center
        latLongLabel.textColor = UIColor(hex: 0xeb8f44)
        bottomBorderForView(latLongLabel)
        latLongLabel.alpha = 0.0
        view.addSubview(latLongLabel)
        latLongLabel.text = ""
        
        //Updated Display
        
        updatedDisplayView = UIView(frame: CGRect(x: 0, y: CGRectGetHeight(self.view.frame) + 120, width: CGRectGetWidth(self.view.bounds), height: 53))
        updatedDisplayView.backgroundColor = UIColor(hex: 0x24c57b)
        view.addSubview(updatedDisplayView)
        
        updatedLabel = UILabel(frame: CGRect(x: CGRectGetMidX(updatedDisplayView.bounds) - (350 / 2), y: CGRectGetMidY(updatedDisplayView.bounds) - (42 / 2), width: 350, height: 42))
        updatedLabel.font = UIFont(name: "Berlin", size: 18.0)
        updatedLabel.numberOfLines = 0
        updatedLabel.lineBreakMode = .ByWordWrapping
        updatedLabel.textAlignment = .Center
        updatedLabel.textColor = UIColor.whiteColor()
        updatedDisplayView.addSubview(updatedLabel)
        
    }
    
    //MARK: - Button Actions
    
    func saveAction(sender:UIButton!) {
        if let placemark = self.placemark {
            AudioServicesPlaySystemSound(tapAudioEffect)
            showMessageBannerWithText("Location Saved", color: UIColor.emeraldColor())
            if let pageVC = self.parentViewController as RAPageViewController? {
                pageVC.addPage(Recent(placemark: placemark, timeStamp: NSDate()))
            }
        } else {
            showMessageBannerWithText("Placemark Error", color: UIColor.alizarinColor())
            var animationVC = self.storyboard?.instantiateViewControllerWithIdentifier("AnimationViewController") as AnimationViewController
            animationVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.presentViewController(animationVC, animated: true, completion: {
                animationVC.showVCAfter(.Retry, after: 1.2)
            })
        }
    }
    
    func shareAction(sender:UIButton!) {
        if let placemark = self.placemark {
            AudioServicesPlaySystemSound(tapAudioEffect)
            let firstActivityItem = "I'm at \(longLocationDescription(placemark)), where are you?"
            
            let activityViewController : UIActivityViewController = UIActivityViewController(
                activityItems: [firstActivityItem], applicationActivities: nil)
            
            activityViewController.excludedActivityTypes = [
                UIActivityTypePostToWeibo,
                UIActivityTypePrint,
                UIActivityTypeAssignToContact,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo,
                UIActivityTypePostToTencentWeibo
            ]
            
            self.presentViewController(activityViewController, animated: true, completion: nil)
        } else {
            showMessageBannerWithText("Placemark Error", color: UIColor.alizarinColor())
            var animationVC = self.storyboard?.instantiateViewControllerWithIdentifier("AnimationViewController") as AnimationViewController
            animationVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.presentViewController(animationVC, animated: true, completion: {
                animationVC.showVCAfter(.Retry, after: 1.2)
            })
        }
    }
    
    func relocateAction(sender:UIButton) {
        AudioServicesPlaySystemSound(tapAudioEffect)
        var animationVC = self.storyboard?.instantiateViewControllerWithIdentifier("AnimationViewController") as AnimationViewController
        animationVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(animationVC, animated: true, completion: {
            animationVC.showVCAfter(.Retry, after: 1.2)
        })
    }
    
    //MARK: - Layer Animations
    
    func startTouchAnimation() {
        let progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        progressAnimation.fromValue = 0.0
        progressAnimation.toValue = 1.0
        progressAnimation.duration = 1.4
        progressAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progressAnimation.removedOnCompletion = false
        progressAnimation.fillMode = kCAFillModeForwards
        progressAnimation.delegate = self
        touchHoldLayer.addAnimation(progressAnimation, forKey: "progress")
    }
    
    func removeTouchAnimation() {
        touchHoldLayer.removeAnimationForKey("progress")
        touchHoldLayer.fillColor = UIColor.clearColor().CGColor
    }
    
    func rotateCompass() {
        var randTime = Double(arc4random_uniform(2) + 2)
        var randAngle = CGFloat(arc4random_uniform(UInt32(M_PI * 2)))
        
        UIView.animateWithDuration(randTime,delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () in
            self.compassView.transform = CGAffineTransformMakeRotation(randAngle)
        }) { _ in
            if self.updatingLocation {
                self.rotateCompass()
            } else {
                UIView.animateWithDuration(0.69,delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () in
                    self.compassView.transform = CGAffineTransformMakeRotation(0)
                    }) { _ in
                        if self.placemark != nil {
                            println("Found PlaceMark")
                            self.removeOldElements()
                        }
                }
            }
        }
    }
    
    //MARK: - Gesture Recongizer Target Action(s)
    
    func dismiss(tap: UITapGestureRecognizer) {
        UIView.animateWithDuration(1.213, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.bouncyAlertView.bounds = CGRect(origin: self.bouncyAlertView.bounds.origin, size: CGSizeZero)
            self.alertLabel.bounds = CGRect(origin: self.alertLabel.bounds.origin, size: CGSizeZero)
            }, completion: { _ in
                //
        })
    }
    
    //MARK: - MapKit Delegate
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        mapView.setCenterCoordinate(userLocation.coordinate, animated: true)
    }
    
    //MARK: - Touch Event Handling
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as? UITouch
        let point = touch!.locationInView(self.view)
        
        for touch in touches {
            if CGRectContainsPoint(compassView.frame, point) {
                if let placemark = placemark {
                    if showingVerbose {
                        showingVerbose = false
                        updateTextByAnimation(shortLocationDescription(placemark))
                    } else {
                        showingVerbose = true
                        updateTextByAnimation(longLocationDescription(placemark))
                    }
                } else {
                    touchHoldLayer.position = CGPoint(x: point.x - 55, y: point.y - 55)
                    let parentVC = self.parentViewController as RAPageViewController
                    AudioServicesPlaySystemSound(tapAudioEffect)
                    parentVC.delegate = nil
                    startTouchAnimation()
                    holding = true
                    updateLabel()
                }
            }
            if CGRectContainsPoint(latLongLabel.frame, point) && showingInformation {
                if self.placemark != nil {
                    AudioServicesPlaySystemSound(tapAudioEffect)
                    let coordinate = CLLocationCoordinate2D(latitude: self.placemark!.location.coordinate.latitude, longitude: self.placemark!.location.coordinate.longitude)
                    let mapPlacemark = MKPlacemark(placemark: self.placemark)
                    let mapItem = MKMapItem(placemark: mapPlacemark)
                    mapItem.openInMapsWithLaunchOptions(nil)
                }
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as? UITouch
        let point = touch!.locationInView(self.view)
        touchHoldLayer.position = CGPoint(x: point.x - 55, y: point.y - 55)
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if !showingInformation {
            removeTouchAnimation()
            let parentVC = self.parentViewController as RAPageViewController
            parentVC.delegate = parentVC.delegate
            holding = false
            updateLabel()
        }
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        if !showingInformation {
            removeTouchAnimation()
            let parentVC = self.parentViewController as RAPageViewController
            parentVC.delegate = parentVC.delegate
            holding = false
            updateLabel()
        }
    }
    
    // MARK: - UIStatusBar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        // TODO: Do something awesome here :)
        return true
    }
    
    // MARK: - Helpers
    
    func showMessageBannerWithText(text: String, color: UIColor) {
        let bannerHeight: CGFloat = 54.0
        var banner = UIView(frame: CGRect(x: 0, y: -bannerHeight - 25, width: self.view.frame.size.width, height: bannerHeight * 2))
        banner.backgroundColor = color
        
        var label = UILabel(frame: CGRect(x: 0, y: 13, width: banner.frame.width, height: (bannerHeight * 2)))
        label.textAlignment = .Center
        label.text = text
        label.font = UIFont(name: "AvenirNext-Medium", size: 37.0)
        label.textColor = UIColor(hex: 0xecf0f1)
        banner.addSubview(label)
        self.view.addSubview(banner)
        let b = banner.bounds
        UIView.animateWithDuration(0.93, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5.0, options: .CurveEaseOut, animations: { () -> Void in
            banner.center = CGPoint(x: b.origin.x + b.size.width/2, y: bannerHeight/2)
            }) { _ in
                UIView.animateWithDuration(0.93, delay: 0.69, usingSpringWithDamping: 0.7, initialSpringVelocity: 4.0, options: .CurveEaseIn, animations: { () -> Void in
                    banner.center = CGPoint(x: b.origin.x + b.size.width/2, y: -bannerHeight)
                    }) { _ in
                        banner.removeFromSuperview()
                }
        }
    }
    
    func resizeImage(image: UIImage, byFactor: Float) -> UIImage {
        let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(CGFloat(byFactor), CGFloat(byFactor)))
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.drawInRect(CGRect(origin: CGPointZero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func showInfoForPlaceMark() {
        showingInformation = true
        let cityD = cityDisplay.bounds
        let placeM = placemarkInfoLabel.bounds
        let updateB = updatedDisplayView.bounds
        UIView.animateWithDuration(0.35, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 5.0, options: nil, animations: { () -> Void in
            self.cityDisplay.alpha = 1.0
            self.cityDisplay.center = CGPoint(x: cityD.origin.x + cityD.size.width/2, y: 35)
            self.cityLabel.text = self.placemark!.locality
            
            self.latLongLabel.alpha = 1.0
            self.latLongLabel.text = "\(self.placemark!.location.coordinate.latitude), \(self.placemark!.location.coordinate.longitude)"
            
            }, completion: { _ in
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.saveButton.alpha = 1.0
                    }, completion: {_ in
                        UIView.animateWithDuration(0.2, animations: { () -> Void in
                            self.shareButton.alpha = 1.0
                            }, completion: {_ in
                                UIView.animateWithDuration(0.2, animations: { () -> Void in
                                    self.relocateButton.alpha = 1.0
                                    }, completion: {_ in
                                        
                                })
                        })
                })
        })
        
        UIView.animateWithDuration(0.35, delay: 0.2, usingSpringWithDamping: 0.4, initialSpringVelocity: 5.0, options: nil, animations: { () -> Void in
            self.mapView.alpha = 1.0
            self.mapView.setCenterCoordinate(self.placemark!.location.coordinate, animated: true)
            self.mapView.showsUserLocation = true
            
            self.placemarkInfoLabel.center = CGPoint(x: 10 + placeM.size.width/2, y: CGRectGetHeight(self.cityDisplay.frame) + CGRectGetHeight(self.mapView.frame) + placeM.size.height/2)
            self.placemarkInfoLabel.text = self.longLocationDescription(self.placemark!)
            }, completion: { _ in
        })

    }
    
    func removeOldElements() {
        let c = compassView.bounds
        let l = locationLabel.bounds
        animateViewToColor(darkColors, duration: colorFadeTime)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.compassView.center = CGPoint(x: CGRectGetMidX(self.view.frame), y: -180)
            self.locationLabel.center = CGPoint(x: l.origin.x + l.size.width/2, y: -180)
            }, completion: { _ in
                self.showInfoForPlaceMark()
        })
    }
    
    func bottomBorderForView(view: UIView) {
        var border = CALayer()
        var width = CGFloat(2.0)
        
        border.borderColor = UIColor.lightGrayColor().CGColor
        border.frame = CGRect(x: 0, y: view.frame.size.height - width, width:  view.frame.size.width, height: view.frame.size.height)
        
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true
    }
    
    func showBouncyAlert(string: String) {
        self.alertLabel.text = string
        UIView.animateWithDuration(1.213, delay: 0.0, usingSpringWithDamping: 0.456, initialSpringVelocity: 9.0, options: nil, animations: { () -> Void in
            self.bouncyAlertView.bounds = CGRect(origin: self.bouncyAlertView.bounds.origin, size: CGSizeMake(self.alertViewSize, self.alertViewSize))
            self.alertLabel.bounds = CGRect(origin: self.alertLabel.bounds.origin, size: CGSizeMake(self.alertLabelSize, self.alertLabelSize))
            }, completion: { _ in
                //
        })
    }
    
    func animateViewToColor(colors: Array<CGColor!>, duration: NSTimeInterval) {
        UIView.animateWithDuration(duration, delay: 0.0, options: .CurveEaseInOut, animations: { ()
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            
            let parent = self.parentViewController as RAPageViewController
            
            parent.gradient.colors = colors
            
            CATransaction.commit()
            }, completion: { _ in
                // Animation did end callback
        })
    }
    
    func updateTextByAnimation(text: String) {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .TransitionFlipFromBottom, animations: { ()
            self.locationLabel.alpha = 0.0
            }, completion: { _ in
                // complete
                self.locationLabel.text = text
                UIView.animateWithDuration(0.2, delay: 0.0, options: .TransitionFlipFromBottom, animations: { ()
                    self.locationLabel.alpha = 1.0
                    }, completion: { _ in
                        // complete
                })
        })
    }
    
    func updateLabel() {
        var status: String = ""
        if holding {
            status = "Keep Holding!"
            updateTextByAnimation(status)
        } else {
            if let location = location {
                
                if let placemark = placemark {
                    animateViewToColor(greenColors, duration: colorFadeTime)
                    if showingVerbose {
                        status = shortLocationDescription(placemark)
                    } else {
                        status = longLocationDescription(placemark)
                    }
                } else if performingReversGeocoding {
                    animateViewToColor(yellowColors, duration: colorFadeTime)
                    status = "Searching For Address..."
                } else if lastGeocodingError != nil {
                    animateViewToColor(redColors, duration: colorFadeTime)
                    status = "Error Finding Address For Location: \(location.coordinate.latitude), \(location.coordinate.longitude)"
                } else {
                    status = "Working..."
                }
                
                updateTextByAnimation(status)
            } else {
                if let error = lastLocationError {
                    if error.domain == kCLErrorDomain &&
                        error.code == CLError.Denied.rawValue {
                            animateViewToColor(redColors, duration: colorFadeTime)
                            status = "Location Services Disabled"
                    } else {
                        animateViewToColor(redColors, duration: colorFadeTime)
                        status = "Error Getting Location"
                    }
                } else if !CLLocationManager.locationServicesEnabled() {
                    animateViewToColor(redColors, duration: colorFadeTime)
                    status = "Location Services Disabled"
                } else if updatingLocation {
                    animateViewToColor(yellowColors, duration: colorFadeTime)
                    status = "Locating..."
                } else {
                    animateViewToColor(darkColors, duration: colorFadeTime)
                    status = "Hold to calculate your location"
                }
                updateTextByAnimation(status)
            }
        }
        
    }
    
    func shortLocationDescription(placemark: CLPlacemark) -> String {
        if placemark.areasOfInterest != nil {
            return "\(placemark.areasOfInterest), \(placemark.administrativeArea)"
        } else {
            return "\(placemark.locality), \(placemark.administrativeArea)"
        }
    }
    
    func longLocationDescription(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare), \(placemark.locality), \(placemark.administrativeArea), \(placemark.postalCode)"
    }
    
    func sharableStringFrom(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare) \(placemark.locality), \(placemark.administrativeArea)"
    }
    
    func getLocation() {
        
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        // TODO: Add fancy animation for a 
        //       detail explination why this app needs location data access
        
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authStatus == .Denied || authStatus == .Restricted {
            animateViewToColor(redColors, duration: colorFadeTime)
            self.locationLabel.text = "Cannot get location"
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        
        updateLabel()
    }
    
    func didTimeOut() {
        println("*** Time Out")
        
        if location == nil {
            stopLocationManager()
            
            lastLocationError = NSError(domain: "WhereaboutsErrorDomain", code: 1, userInfo: nil)
            
            updateLabel()
        }
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Oh No! :(",
        message:
        "This app needs access to your phones location, please enable is in your privacy settings!",
        preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        presentViewController(alert, animated: true, completion: nil)
        
        alert.addAction(okAction)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(35, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
            
            updateLabel()
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            
            println("Stopping, and saving to shared user defaults")
            let sharedDefaults = NSUserDefaults(suiteName: "group.net.naturaln0va.Whereabouts")
            var sharableLocationString: String = "Location not found :("
            if let placemark = placemark {
                sharableLocationString = sharableStringFrom(placemark)
            } else {
                if let location = location {
                    sharableLocationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                }
            }
            sharedDefaults?.setObject(sharableLocationString, forKey: "location")
            sharedDefaults?.setObject(NSDate(), forKey: "date")
            
            if let location = sharedDefaults?.objectForKey("location") as? String {
                println("Saved \(location) successfully!")
            }
            
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            updateLabel()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("didFailWithError \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        
        updateLabel()
        
        stopLocationManager()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newLocaiton = locations.last as CLLocation
        println("didUpdateLocations \(newLocaiton)")
        
        if newLocaiton.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocaiton.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocaiton.distanceFromLocation(location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocaiton.horizontalAccuracy {
            
            lastLocationError = nil
            location = newLocaiton
            updateLabel()
            
            if newLocaiton.horizontalAccuracy <= locationManager.desiredAccuracy {
                
                println("*** We're Done")
                stopLocationManager()
                
                if distance > 0 {
                    performingReversGeocoding = false
                }
            }
        }
        
        if !performingReversGeocoding {
            println("*** Going to Geocode")
            
            performingReversGeocoding = true
            
            updateLabel()
            
            geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                
                self.lastGeocodingError = error
                if error == nil && !placemarks.isEmpty {
                    self.placemark = placemarks.last as? CLPlacemark
                } else {
                    self.placemark = nil
                }
                
                self.performingReversGeocoding = false
                self.updateLabel()
                self.stopLocationManager()
            })
        } else if distance < 1.0 {
            let timeInterval = newLocaiton.timestamp.timeIntervalSinceDate(location!.timestamp)
            
            if timeInterval > 10 {
                println("*** Force Done!")
                stopLocationManager()
                updateLabel()
            }
        }
    }

}