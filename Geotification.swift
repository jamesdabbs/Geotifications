import UIKit
import MapKit
import CoreLocation

class Geotification: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var radius: CLLocationDistance
  var identifier: String?
  var name: String?

  var title: String? {
    return identifier
  }

  var subtitle: String? {
    return "Radius: \(radius)m"
  }

  init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String?, name: String?) {
    self.coordinate = coordinate
    self.radius     = radius
    self.identifier = identifier
    self.name       = name
  }
  
  func region() -> CLCircularRegion {
    let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier!)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    return region
  }
  
  // MARK: JSON serialization
  
  func toJSON() -> NSData {
    let params = [
      "latitude":   coordinate.latitude,
      "longitude":  coordinate.longitude,
      "radius":     radius,
      "identifier": identifier!
      ]
    if let n = name {
      params.setValue(n, forKey: "name")
    }
    let json = try! NSJSONSerialization.dataWithJSONObject(params, options: [])
    return json
  }
  
  class func fromJSON(data: NSDictionary) -> Geotification {
    let lat = data["latitude"] as! CLLocationDegrees
    let lon = data["longitude"] as! CLLocationDegrees
    let coordinate = CLLocationCoordinate2DMake(lat, lon)
    
    let radius = data["radius"] as! CLLocationDistance
    let identifier = data["uuid"] as! String
    let name = data["name"] as? String
    return Geotification(coordinate: coordinate, radius: radius, identifier: identifier, name: name)
  }
}
