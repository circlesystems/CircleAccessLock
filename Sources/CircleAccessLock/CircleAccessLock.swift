import Foundation
import UIKit
import WebKit

@available(iOS 13.0, *)
public final class CircleAccessLock: NSObject {
  private weak var parentViewController: UIViewController?
  private var webViewController: CircleViewController?

  public init(parentViewController: UIViewController, initialUrl: String = CircleViewController.defaultUrl) {
    self.parentViewController = parentViewController

    self.webViewController = CircleViewController(initialUrl: initialUrl)

    super.init()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(sceneWillEnterForeground(_:)),
      name: UIScene.willEnterForegroundNotification,
      object: nil
    )
  }

  @objc private func sceneWillEnterForeground(_ notification: Notification) {
    guard let parentViewController = parentViewController else { return }
    presentWebViewController(parentViewController: parentViewController)
  }

  private func presentWebViewController(parentViewController: UIViewController) {
    guard let webViewController = webViewController else { return }

    // Circle Browser
    let now = Date().timeIntervalSinceReferenceDate
    let lastTime = CircleViewController.getLastTime() ?? 0
    let maxTime = CircleViewController.getMaxTime()

    if  CGFloat(now - lastTime) > CGFloat(maxTime) {
      webViewController.modalPresentationStyle = .fullScreen
      parentViewController.present(webViewController, animated: true, completion: nil)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

@available(iOS 13.0, *)
public class CircleViewController: UIViewController {

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(initialUrl: String) {
    self.initialUrl = initialUrl
    super.init(nibName: nil, bundle: nil)
  }

  public static let defaultUrl: String = "https://unic-auth.web.app/circlebrowser/"

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupWebview()
    setupLoadingView()
  }

  private func setupWebview() {
    view.addSubview(webView)
    webView.backgroundColor = .white
    webView.uiDelegate = self
    webView.navigationDelegate = self
    webView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])

    let gearImage = UIImage(systemName: "gear")
    let gearButton = UIBarButtonItem(image: gearImage, style: .plain, target: self, action: #selector(gearButtonTapped))
    navigationItem.rightBarButtonItem = gearButton

    DispatchQueue.main.async {
      if let url = URL(string: self.getSavedUrl()) {
        let urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        self.webView.load(urlRequest)
      }
    }

    // Let's add a view to avoid tap
    let coverView = UIView()
    coverView.isUserInteractionEnabled = true
    coverView.backgroundColor = .clear
    view.addSubview(coverView)
    coverView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      coverView.topAnchor.constraint(equalTo: view.topAnchor),
      coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    view.bringSubviewToFront(coverView)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap))
    coverView.addGestureRecognizer(tapGesture)
  }

  private func getSavedUrl() -> String {
    if let url = CircleViewController.getSavedURL() {
        return url
    }
    return CircleViewController.defaultUrl
  }

  @objc func handleOverlayTap(_ sender: UITapGestureRecognizer) {
    // Do nothing, the overlay view will block any taps on the web view
  }

  @objc func gearButtonTapped() {
    let url = URL(string: Self.defaultUrl)
    if let url = url {
      let request = URLRequest(url: url)
      webView.load(request)
    }
  }

  private func setupLoadingView() {
    view.addSubview(activityIndicator)
  }

  private let initialUrl: String
  private let webView = WKWebView()
  private lazy var activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(style: .large)
    activityIndicator.center = view.center
    return activityIndicator
  }()
}


@available(iOS 13.0, *)
extension CircleViewController: WKUIDelegate, WKNavigationDelegate {
  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url {
      if url.scheme == "circlebrowser" {
        if url.absoluteString.hasPrefix("circlebrowser://save=") {
          let urlString = url.absoluteString.dropFirst("circlebrowser://save=".count)

          if urlString.contains("?max_time=") {
            let components = urlString.components(separatedBy: "?max_time=")
            let baseUrl = components[0]
            let maxTime = components[1]
            CircleViewController.saveURL(url: String(baseUrl))
            DispatchQueue.main.async {
              self.showSavedAlert(url: String(baseUrl))
            }

            if let doubleMax = Double(maxTime) {
              CircleViewController.saveMaxTime(time: doubleMax)
            }
          } else {
            CircleViewController.saveURL(url: String(urlString))
            DispatchQueue.main.async {
              self.showSavedAlert(url: String(urlString))
            }
          }

        } else if url.absoluteString == "circlebrowser://dismiss" {
          callDismiss()
        }
        decisionHandler(.cancel)
        return
      }
    }
    decisionHandler(.allow)
  }

  private func callDismiss() {
    let now = Date().timeIntervalSinceReferenceDate
    CircleViewController.saveTime(time: now)
    dismiss(animated: true, completion: nil)
  }

  public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    activityIndicator.startAnimating()
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    activityIndicator.stopAnimating()
  }

  public static func getSavedURL() -> String? {
    let userDefaults = UserDefaults.standard
    return userDefaults.string(forKey: "savedURL")
  }

  static func saveURL(url: String) {
    let userDefaults = UserDefaults.standard
    return userDefaults.set(url.removingPercentEncoding, forKey: "savedURL")
  }

  static func getLastTime() -> TimeInterval? {
    let userDefaults = UserDefaults.standard
    return userDefaults.double(forKey: "lastTime")
  }

  static func saveTime(time: TimeInterval) {
    let userDefaults = UserDefaults.standard
    return userDefaults.set(time, forKey: "lastTime")
  }

  static func saveMaxTime(time: TimeInterval) {
    let userDefaults = UserDefaults.standard
    return userDefaults.set(time, forKey: "maxTime")
  }

  static func getMaxTime() -> TimeInterval {
    let userDefaults = UserDefaults.standard
    let maxTime = userDefaults.double(forKey: "maxTime")
    return maxTime == 0 ? (10 * 60) : maxTime // 10 min default
  }

  func showSavedAlert(url: String) {
    let alertController = UIAlertController(title: "Configuration saved", message: "Your configuration has been saved successfully. You will be automatically redirected to the end-user login website to log in with your credentials.", preferredStyle: .alert)
    present(alertController, animated: true)

    _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak alertController, weak self] _ in
      alertController?.dismiss(animated: true)
      if let decodedString = url.removingPercentEncoding {
        if let insideUrl = URL(string: decodedString) {
          self?.webView.load(URLRequest(url: insideUrl))
        }
      }
    }
  }
}
