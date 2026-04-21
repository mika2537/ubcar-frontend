import Flutter
import UIKit
import GoogleMaps   // ✅ ADD THIS

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GMSServices.provideAPIKey("AIzaSyBGsEqb6Fs9co0yGP6syLKZNF9eyC4LAO4") // ✅ ADD THIS

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}