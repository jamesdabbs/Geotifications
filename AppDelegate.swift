import UIKit
import CoreLocation

import AWSCore
import AWSSQS



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

  var window: UIWindow?
  let locationManager = CLLocationManager()
  let geotificationManager = GeotificationManager() // TODO: share this w/ ViewController

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    geotificationManager.fetchAll({}) // TODO: what if this fetch hasn't finished by the time we need it?

    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    for region in locationManager.monitoredRegions {
      locationManager.stopMonitoringForRegion(region)
    }
    
    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = AWS_CONFIG
    
    application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
    UIApplication.sharedApplication().cancelAllLocalNotifications()
    
    return true
  }

  func handleRegionEvent(region: CLRegion!, direction: EventType) {
    guard region is CLCircularRegion else {
      print("Can't handle non-circular regions")
      return
    }
    
    if let geotification = geotificationManager.geotificationFromRegionIdentifier(region.identifier) {
      Checkin(location: geotification, direction: direction).publish()
      
      if UIApplication.sharedApplication().applicationState == .Active {
        if let viewController = window?.rootViewController {
          showSimpleAlertWithTitle(nil, message: geotification.note, viewController: viewController)
        }
      } else {
        let notification = UILocalNotification()
        notification.alertBody = geotification.note
        notification.soundName = "Default"
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
      }
    }
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    handleRegionEvent(region, direction: .OnEntry)
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    handleRegionEvent(region, direction: .OnExit)
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}

