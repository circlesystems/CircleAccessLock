import XCTest
@testable import CircleAccessLock

@available(iOS 13.0, *)
final class CircleAccessLockTests: XCTestCase {
  var window: UIWindow!
  var parentViewController: UIViewController!

  override func setUpWithError() throws {
    window = UIWindow(frame: UIScreen.main.bounds)
    parentViewController = UIViewController()
    window.rootViewController = parentViewController
    window.makeKeyAndVisible()
  }

  override func tearDownWithError() throws {
    window = nil
    parentViewController = nil
  }

  func testSceneLifecycleWebViewInitialization() {
    let sceneLifecycleWebView = CircleAccessLock(parentViewController: parentViewController)
    XCTAssertNotNil(sceneLifecycleWebView, "CircleAccessLock should be initialized")
  }

  func testSceneLifecycleWebViewTrigger() {
      let sceneLifecycleWebView = CircleAccessLock(parentViewController: parentViewController)
      XCTAssertNotNil(sceneLifecycleWebView, "SceneLifecycleWebView should be initialized")
  }
}
