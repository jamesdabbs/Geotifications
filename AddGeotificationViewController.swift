import UIKit
import MapKit

protocol AddGeotificationsViewControllerDelegate {
  func addGeotificationViewController(controller: AddGeotificationViewController, didUpdateLocation location: Geotification)
  
  func addGeotificationViewController(controller: AddGeotificationViewController, didRemoveLocation location: Geotification)
}

class AddGeotificationViewController: UITableViewController, MKMapViewDelegate {

  @IBOutlet var saveButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var idLabel: UILabel!
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var radiusLabel: UILabel!
  @IBOutlet weak var checkinDebugButtons: UISegmentedControl!
  @IBOutlet weak var deleteButton: UIButton!

  // Question: what's the right way to share the other annotations from the main map view?
  var delegate: AddGeotificationsViewControllerDelegate!
  
  var location: Geotification!
  
  var coordinate: CLLocationCoordinate2D?
  var radius: CLLocationDistance? {
    didSet {
      if let r = radius {
        radiusLabel.text = "\(Int(r))m"
        updateOverlay()
      }
    }
  }
  
  var editingOverlay: MKCircle?

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = (location?.identifier == nil) ? "New Location" : "Update Location"
    navigationItem.rightBarButtonItems = [saveButton, zoomButton]

    tableView.tableFooterView = UIView()
    
    coordinate = location.coordinate
    radius = location.radius
    
    if location.identifier == nil {
      checkinDebugButtons.enabled = false
      deleteButton.enabled = false
    } else {
      idLabel.text = location.identifier
      nameField.text = location.name
//      radiusSlider.value = Float(location.radius)
    }
    
    let region = MKCoordinateRegionMakeWithDistance(coordinate!, 1000, 1000)
    mapView.setRegion(region, animated: true)
    mapView.scrollEnabled = false // for now, at least - the overlays would break
    
    for location in GeotificationManager.sharedInstance.all {
      mapView.addOverlay(MKCircle(centerCoordinate: location.coordinate, radius: location.radius))
    }
  }
  
  // MARK - Actions
  
  @IBAction private func onRadiusSliderChange(sender: UISlider) {
    radius = CLLocationDistance(Int(sender.value))
  }

  @IBAction private func onCancel(sender: AnyObject) {
    back()
  }
  
  @IBAction private func onSave(sender: AnyObject) {
    (location == nil || location!.identifier == nil) ? saveLocation() : updateLocation()
    back()
  }
  
  @IBAction private func onDelete(sender: AnyObject) {
    deleteLocation()
    back()
  }

  @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
  
  @IBAction private func onTriggerCheckin(sender: UISegmentedControl) {
    if let l = location {
      let direction = (checkinDebugButtons.selectedSegmentIndex == 0) ? EventType.OnEntry : EventType.OnExit
      let checkin = Checkin(location: l, direction: direction)
      checkin.publish()
    }
  }
  
  // MARK - MapView delegate methods
  
  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
    let circleRenderer = MKCircleRenderer(overlay: overlay)
    circleRenderer.lineWidth = 1.0
    if (overlay.coordinate.latitude == coordinate!.latitude && overlay.coordinate.longitude == coordinate!.longitude) {
      circleRenderer.strokeColor = UIColor.purpleColor()
      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
    } else {
      circleRenderer.strokeColor = UIColor.init(red: 0.5, green: 0, blue: 0.5, alpha: 0.3)
      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.1)
    }
    return circleRenderer
  }
  
  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    coordinate = mapView.centerCoordinate
  }
  
  // MARK - private helpers
  
  private func updateOverlay() {
    // Question: is there a better way to update without removing?
    if let overlay = editingOverlay {
      mapView.removeOverlay(overlay)
    }
    
    editingOverlay = MKCircle(centerCoordinate: coordinate!, radius: radius!)
    mapView.addOverlay(editingOverlay!)
  }

  private func saveLocation() {
    let identifier = NSUUID().UUIDString
    location = Geotification(coordinate: coordinate!, radius: radius!, identifier: identifier, name: nil)
    
    delegate!.addGeotificationViewController(self, didUpdateLocation: location!)
  }
  
  private func updateLocation() {
    location!.coordinate = coordinate!
    location!.radius = radius!
    
    delegate!.addGeotificationViewController(self, didUpdateLocation: location!)
  }
  
  private func deleteLocation() {
    delegate!.addGeotificationViewController(self, didRemoveLocation: location!)
  }
  
  private func back() {
    dismissViewControllerAnimated(true, completion: nil)
  }
}
