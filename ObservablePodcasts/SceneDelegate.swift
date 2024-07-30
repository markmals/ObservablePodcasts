import UIKit
import SwiftSignal

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        let navigationController = UINavigationController()
//        let podcastList = PodcastListViewController()
        let podcastList = ViewController()
        
        navigationController.setViewControllers([podcastList], animated: false)
        navigationController.navigationBar.prefersLargeTitles = true
        
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let count = Signal(initialValue: 0)

        func startCounter() {
            Task {
                while true {
                    try? await Task.sleep(for: .seconds(1))
                    count.update { $0 + 1 }
                }
            }
        }
        
        let label = UXLabel("A number: \(count())")
        label.nativeView.center = view.center
        label.nativeView.sizeToFit()
        view.addSubview(label.nativeView)
        
        startCounter()
        print("counter started")
    }
}
