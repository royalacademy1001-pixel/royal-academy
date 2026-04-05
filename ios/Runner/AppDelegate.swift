import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  var secureView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptured),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func screenCaptured() {
    if UIScreen.main.isCaptured {
      addSecureView()
    } else {
      removeSecureView()
    }
  }

  func addSecureView() {
    guard let window = UIApplication.shared.windows.first else { return }

    if secureView != nil { return }

    let view = UIView(frame: window.bounds)
    view.backgroundColor = UIColor.black

    let label = UILabel(frame: view.bounds)
    label.text = "🔒 المحتوى محمي"
    label.textColor = UIColor.white
    label.textAlignment = .center

    view.addSubview(label)

    window.addSubview(view)
    secureView = view
  }

  func removeSecureView() {
    secureView?.removeFromSuperview()
    secureView = nil
  }
}