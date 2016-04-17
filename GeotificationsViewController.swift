import UIKit
import MapKit
// import CoreLocation


class GeotificationsViewController: UIViewController, AddGeotificationsViewControllerDelegate, MKMapViewDelegate {

  @IBOutlet weak var mapView: MKMapView!

  var geotifications = GeotificationManager.sharedInstance
  
  var selected : Geotification?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // This _does_ presuppose that we have the user location
    mapView.showsUserLocation = true
    
    // Question: should this be an observer / notifier?
    geotifications.fetchAll() {
      dispatch_async(dispatch_get_main_queue(), {
        self.redrawPins()
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
      })
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "addGeotification" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
      vc.location = selected
    }
  }
  
  @IBAction func onLongPress(gestureRecognizer: UIGestureRecognizer) {
    let touchPoint = gestureRecognizer.locationInView(mapView)
    let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
    
    selected = Geotification(coordinate: coordinate, radius: 100, identifier: nil, name: nil)
    self.performSegueWithIdentifier("addGeotification", sender: self)
  }

  // MARK: rendering
  
  func redrawPins() {
    // Clear map
    mapView.removeOverlays(mapView.overlays)
    mapView.removeAnnotations(mapView.annotations)
    
    // Repopulate
    for location in geotifications.all {
      mapView.addAnnotation(location)
      mapView.addOverlay(MKCircle(centerCoordinate: location.coordinate, radius: location.radius))
    }
    
    // Update title bar
    title = "Locations [\(geotifications.count())]"
    navigationItem.rightBarButtonItem?.enabled = (geotifications.count() < 20)
  }

  // MARK: AddGeotificationViewControllerDelegate

  func addGeotificationViewController(controller: AddGeotificationViewController, didUpdateLocation location: Geotification) {
    geotifications.register(location)
    redrawPins()
  }
  
  func addGeotificationViewController(controller: AddGeotificationViewController, didRemoveLocation location: Geotification) {
    geotifications.unregister(location)
    redrawPins()
  }

  // MARK: MKMapViewDelegate

  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
    let circleRenderer = MKCircleRenderer(overlay: overlay)
    circleRenderer.lineWidth = 1.0
    circleRenderer.strokeColor = UIColor.purpleColor()
    circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
    return circleRenderer
  }
  
  func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
    if let location = view.annotation as? Geotification {
      selected = location
      performSegueWithIdentifier("addGeotification", sender: self)
    }
  }

  // MARK: Other mapview functions

  @IBAction private func zoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
}
