import UIKit

class GeotificationManager {
  var all = [Geotification]()
  
  class func loadAllGeotifications(onComplete: [Geotification] -> ()) {
    var geotifications = [Geotification]()
    
    let url = "http://localhost:4567/geotifications"
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    
    let session = NSURLSession.sharedSession()
    request.HTTPMethod = "GET"
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      let response = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
      print("response: \(response)")
      for (_,geotification) in response {
        geotifications.append(Geotification.fromJSON(geotification as! NSDictionary))
      }
      onComplete(geotifications)
    })
    task.resume()
  }
  
  func add(geotification: Geotification) {
    all.append(geotification)
    
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    
    let url = "http://localhost:4567/geotifications"
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    
    let session = NSURLSession.sharedSession()
    request.HTTPMethod = "POST"
    request.HTTPBody = geotification.toJSON()
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      guard data != nil else {
        print("Failed to create geotification: \(error)")
        return
      }
    })
    task.resume()
  }
  
  func delete(geotification: Geotification) {
    // TODO: make delete request
    if let indexInArray = all.indexOf(geotification) {
      all.removeAtIndex(indexInArray)
    }
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
