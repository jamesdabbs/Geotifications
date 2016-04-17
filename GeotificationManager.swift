import UIKit
import CoreLocation

class GeotificationManager: NSObject, CLLocationManagerDelegate {
  static let sharedInstance = GeotificationManager()
  
  let locationManager = CLLocationManager()
  
  var all = [Geotification]()
  
  override init() {
    super.init()
    
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
  }
  
  class func request(verb: String, endpoint: String, body: NSData?, complete: (NSDictionary -> ())?) {
    let url = "\(SERVER_URL)\(endpoint)"
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    let session = NSURLSession.sharedSession()
    
    request.HTTPMethod = verb
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("bearer \(DEVICE_UUID)", forHTTPHeaderField: "Authorization")
    
    request.HTTPBody = body
    
    let app = UIApplication.sharedApplication()
    app.networkActivityIndicatorVisible = true
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
      app.networkActivityIndicatorVisible = false
      
      // TODO: actual error handling
      let parsed = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
      
      complete?(parsed)
    })
    task.resume()
  }
  
  
  class func loadAllGeotifications(onComplete: [Geotification] -> ()) {
    request("GET", endpoint: "/locations", body: nil, complete: { response in
      var geotifications = [Geotification]()
      for gd in response["locations"] as! NSArray {
        geotifications.append(Geotification.fromJSON(gd as! NSDictionary))
      }
      onComplete(geotifications)
    })
  }
  
  func register(geotification: Geotification) {
    // Question: is there a better way to "update" monitoring?
    // Question: what to do with the UI if an API call fails (and similarly for unregister)?
    if let i = all.indexOf({$0.identifier == geotification.identifier}) {
      let old = all.removeAtIndex(i)
      stopMonitoring(old)
      
      GeotificationManager.request("PUT", endpoint: "/locations/\(geotification.identifier!)", body: geotification.toJSON(), complete: nil)
    } else {
      GeotificationManager.request("POST", endpoint: "/locations", body: geotification.toJSON(), complete: nil)
    }
    
    startMonitoring(geotification)
    all.append(geotification)
  }
  
  func unregister(geotification: Geotification) {
    if let indexInArray = all.indexOf(geotification) {
      all.removeAtIndex(indexInArray)
    }
    stopMonitoring(geotification)
    
    GeotificationManager.request("DELETE", endpoint: "/locations/\(geotification.identifier!)", body: nil, complete: nil)
  }
  
  func fetchAll(then: () -> ()) {
    GeotificationManager.loadAllGeotifications({ result in
      self.all = result
      then()
    })
  }
  
  func count() -> Int {
    return all.count
  }
  
  func geotificationFromRegionIdentifier(identifier: String) -> Geotification? {
    for g in all {
      if g.identifier == identifier {
        return g
      }
    }
    return nil
  }
  
  // MARK - CLLocationManager delegate methods
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    print("Location authorization status changed: \(status)")
  }
  
  func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
    print("Monitoring failed for region \(region?.identifier)")
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print("Location manager failed: \(error)")
  }
  
  // MARK - other LocationManager methods
  
  func monitoredRegionFor(geotification: Geotification) -> CLCircularRegion? {
    for r in locationManager.monitoredRegions {
      if let circle = r as? CLCircularRegion {
        if circle.identifier == geotification.identifier {
          return circle
        }
      }
    }
    return nil
  }
  
  func startMonitoring(geotification: Geotification) {
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      print("Geofencing is not supported")
      return
    }
    
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      print("Geotification saved, but will not be enabled until you allow access to the device location")
    }
    
    locationManager.startMonitoringForRegion(geotification.region())
  }
  
  func stopMonitoring(geotification: Geotification) {
    if let r = monitoredRegionFor(geotification) {
      locationManager.stopMonitoringForRegion(r)
    }
  }
}
