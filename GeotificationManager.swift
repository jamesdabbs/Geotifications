import UIKit

class GeotificationManager {
  var all = [Geotification]()
  
  class func request(verb: String, endpoint: String, body: NSData?, complete: (NSDictionary -> ())?) {
    let url = "http://localhost:4567\(endpoint)"
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    let session = NSURLSession.sharedSession()
    
    request.HTTPMethod = verb
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    if body != nil {
      request.HTTPBody = body
    }
    
    let app = UIApplication.sharedApplication()
    app.networkActivityIndicatorVisible = true
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
      app.networkActivityIndicatorVisible = false
      
      // TODO: actual error handling
      let parsed = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
      
      if let _complete = complete {
        _complete(parsed)
      }
    })
    task.resume()
  }
  
  
  class func loadAllGeotifications(onComplete: [Geotification] -> ()) {
    request("GET", endpoint: "/geotifications", body: nil, complete: { response in
      var geotifications = [Geotification]()
      for (_,gd) in response {
        geotifications.append(Geotification.fromJSON(gd as! NSDictionary))
      }
      onComplete(geotifications)
    })
  }
  
  func add(geotification: Geotification) {
    all.append(geotification)
    // TODO: remove from UI if API save fails
    GeotificationManager.request("POST", endpoint: "/geotification", body: geotification.toJSON(), complete: nil)
  }
  
  func delete(geotification: Geotification) {
    if let indexInArray = all.indexOf(geotification) {
      all.removeAtIndex(indexInArray)
    }
    // TODO: what if the delete fails?
    GeotificationManager.request("DELETE", endpoint: "/geotifications/\(geotification.identifier)", body: nil, complete: nil)
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
  
  func noteFromRegionIdentifier(identifier: String) -> String? {
    for g in all {
      if g.identifier == identifier {
        return g.note
      }
    }
    return nil
  }
}
