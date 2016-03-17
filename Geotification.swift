import UIKit
import MapKit
import CoreLocation

enum EventType: Int {
  case OnEntry = 0
  case OnExit
}

class Geotification: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var radius: CLLocationDistance
  var identifier: String
  var note: String
  var eventType: EventType

  var title: String? {
    if note.isEmpty {
      return "No Note"
    }
    return note
  }

  var subtitle: String? {
    let eventTypeString = eventType == .OnEntry ? "On Entry" : "On Exit"
    return "Radius: \(radius)m - \(eventTypeString)"
  }

  init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String, eventType: EventType) {
    self.coordinate = coordinate
    self.radius     = radius
    self.identifier = identifier
    self.note       = note
    self.eventType  = eventType
  }
  
  // MARK: JSON serialization
  
  func toJSON() -> NSData {
    let params = [
      "latitude":   coordinate.latitude,
      "longitude":  coordinate.longitude,
      "radius":     radius,
      "identifier": identifier,
      "name":       note
      ]
    let json = try! NSJSONSerialization.dataWithJSONObject(params, options: [])
    return json
  }
  
  class func fromJSON(data: NSDictionary) -> Geotification {
    let lat = data["latitude"] as! CLLocationDegrees
    let lon = data["longitude"] as! CLLocationDegrees
    let coordinate = CLLocationCoordinate2DMake(lat, lon)
    
    let radius = data["radius"] as! CLLocationDistance
    let identifier = data["uuid"] as! String
    let note = data["name"] as! String
    return Geotification(coordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: .OnEntry)
  }
}
