import UIKit

class GeotificationManager {
  var all = [Geotification]()
  
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
  
  func add(geotification: Geotification) {
    all.append(geotification)
    // TODO: remove from UI if API save fails
    GeotificationManager.request("POST", endpoint: "/locations", body: geotification.toJSON(), complete: nil)
  }
  
  func delete(geotification: Geotification) {
    if let indexInArray = all.indexOf(geotification) {
      all.removeAtIndex(indexInArray)
    }
    // TODO: what if the delete fails?
    GeotificationManager.request("DELETE", endpoint: "/locations/\(geotification.identifier)", body: nil, complete: nil)
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
}
