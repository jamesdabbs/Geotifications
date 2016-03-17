import UIKit

import AWSSQS


class Checkin: NSObject {
  var location: Geotification
  var direction: EventType
  
  init(location: Geotification, direction: EventType) {
    self.location  = location
    self.direction = direction
  }
  
  func publish() {
    let msg         = AWSSQSSendMessageRequest()
    msg.queueUrl    = CHECKIN_QUEUE_URL
    msg.messageBody = toJSON()
    AWSSQS.defaultSQS().sendMessage(msg)
  }
  
  func toJSON() -> String {
    // TODO actual latitude and longitude at time of checkin
    let params: Dictionary<String, AnyObject> = [
      "device":    DEVICE_UUID,
      "location":  location.identifier,
      "at":        standardizeDate(NSDate()),
      "direction": (direction == .OnEntry ? "entering" : "exiting")
    ]
    return stringify(params)
  }
}
