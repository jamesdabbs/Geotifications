//
//  GeotificationsViewController.swift
//  Geotify
//
//  Created by Ken Toh on 24/1/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class GeotificationsViewController: UIViewController, AddGeotificationsViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

  @IBOutlet weak var mapView: MKMapView!

  var geotifications = GeotificationManager()
  let locationManager = CLLocationManager()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    // TODO: package this fetch up a little better
    geotifications.fetchAll() {
      dispatch_async(dispatch_get_main_queue(), {
        for geotification in self.geotifications.all {
          self.attachGeotification(geotification)
        }
      })
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "addGeotification" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
    }
  }
  
  // MARK: CLLocationManager delegate methods
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .AuthorizedAlways)
  }
  
  func regionWithGeotification(geotification: Geotification) -> CLCircularRegion {
    let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
    if (geotification.eventType == .OnEntry) {
      region.notifyOnEntry = true
    } else {
      region.notifyOnExit = true
    }
    return region
  }
  
  func startMonitoringGeotification(geotification: Geotification) {
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      showSimpleAlertWithTitle("Error", message: "Geofencing is not supported", viewController: self)
      return
    }
    
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showSimpleAlertWithTitle("Warning", message: "Geotification saved, but will not be enabled until you allow access to the device location", viewController: self)
    }
    let region = regionWithGeotification(geotification)
    locationManager.startMonitoringForRegion(region)
  }
  
  func stopMonitoringGeotification(geotification: Geotification) {
    for region in locationManager.monitoredRegions {
      if let circle = region as? CLCircularRegion {
        if circle.identifier == geotification.identifier {
          locationManager.stopMonitoringForRegion(circle)
        }
      }
    }
  }
  
  func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
    print("Monitoring failed for region \(region?.identifier)")
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print("Location manager failed: \(error)")
  }

  // MARK: Functions that update the model/associated views with geotification changes

  func attachGeotification(geotification: Geotification) {
    mapView.addAnnotation(geotification)
    addRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func removeGeotification(geotification: Geotification) {
    geotifications.delete(geotification)
    mapView.removeAnnotation(geotification)
    removeRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func updateGeotificationsCount() {
    title = "Geotifications (\(geotifications.count()))"
    navigationItem.rightBarButtonItem?.enabled = (geotifications.count() < 20)
  }

  // MARK: AddGeotificationViewControllerDelegate

  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius
    // Add geotification
    let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
    attachGeotification(geotification)
    geotifications.add(geotification)
    startMonitoringGeotification(geotification)
  }

  // MARK: MKMapViewDelegate

  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
    let identifier = "myGeotification"
    if annotation is Geotification {
      var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        let removeButton = UIButton(type: .Custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(named: "DeleteGeotification")!, forState: .Normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }

  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
    if overlay is MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = UIColor.purpleColor()
      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
      return circleRenderer
    }
    return nil
  }

  func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    let geotification = view.annotation as! Geotification
    stopMonitoringGeotification(geotification)
    removeGeotification(geotification)
  }

  // MARK: Map overlay functions

  func addRadiusOverlayForGeotification(geotification: Geotification) {
    mapView?.addOverlay(MKCircle(centerCoordinate: geotification.coordinate, radius: geotification.radius))
  }

  func removeRadiusOverlayForGeotification(geotification: Geotification) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if let circleOverlay = overlay as? MKCircle {
          let coord = circleOverlay.coordinate
          if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
            mapView?.removeOverlay(circleOverlay)
            break
          }
        }
      }
    }
  }

  // MARK: Other mapview functions

  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
}
