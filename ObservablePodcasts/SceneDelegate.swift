import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        let navigationController = UINavigationController()
        let podcastList = PodcastViewController()

        navigationController.setViewControllers([podcastList], animated: false)
        navigationController.navigationBar.prefersLargeTitles = true

        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}
