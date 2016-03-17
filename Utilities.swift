import UIKit
import MapKit

// MARK: Helper Functions

func showSimpleAlertWithTitle(title: String!, message: String, viewController: UIViewController) {
  let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
  let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
  alert.addAction(action)
  viewController.presentViewController(alert, animated: true, completion: nil)
}

func zoomToUserLocationInMapView(mapView: MKMapView) {
  if let coordinate = mapView.userLocation.location?.coordinate {
    let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
    mapView.setRegion(region, animated: true)
  }
}

// MARK: Formatting Functions

func stringify(data: AnyObject) -> String {
  let json = try! NSJSONSerialization.dataWithJSONObject(data, options: [])
  return String(data: json, encoding: NSUTF8StringEncoding)!
}

func standardizeDate(date: NSDate) -> String {
  let dateFormatter = NSDateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

  return dateFormatter.stringFromDate(date)  
}