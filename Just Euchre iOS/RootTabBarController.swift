//
//  RootTabBarController.swift
//  Just Euchre iOS
//

import UIKit

final class RootTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let gameViewController = GameViewController()
    private let homeNav = UINavigationController(rootViewController: HomeViewController())

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        let home = homeNav.viewControllers.first as! HomeViewController
        home.onStartNewGame = { [weak self] in
            self?.startNewGame()
        }
        home.onResumeGame = { [weak self] in
            self?.showGame()
        }

        let settings = SettingsViewController()

        homeNav.setNavigationBarHidden(true, animated: false)
        let settingsNav = UINavigationController(rootViewController: settings)
        settingsNav.setNavigationBarHidden(true, animated: false)

        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 1)

        viewControllers = [homeNav, settingsNav]
        selectedIndex = 0

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
        appearance.shadowColor = UIColor(white: 1, alpha: 0.08)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = UIColor.white
        tabBar.unselectedItemTintColor = UIColor(white: 0.55, alpha: 1)
    }

    private func startNewGame() {
        gameViewController.startNewGameFromMenu()
        showGame()
    }

    private func showGame() {
        selectedIndex = 0
        homeNav.setNavigationBarHidden(true, animated: false)
        if homeNav.topViewController !== gameViewController {
            homeNav.pushViewController(gameViewController, animated: true)
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        (viewController as? UINavigationController)?.popToRootViewController(animated: false)
    }
}
