//
//  ReachabilityClass.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import Foundation
import Reachability
import UIKit

class ReachabilityManager {
    static let shared = ReachabilityManager()
    private var reachability: Reachability!
    private var isMonitoring = false

    private init() {
        setupReachability()
    }

    private func setupReachability() {
        do {
            reachability = try Reachability()
            
            // Setup network status change observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(networkStatusChanged(_:)),
                name: .reachabilityChanged,
                object: reachability
            )
            
            try reachability.startNotifier()
            isMonitoring = true
        } catch {
            print("Unable to start notifier: \(error)")
        }
    }
    
    @objc private func networkStatusChanged(_ notification: Notification) {
        // You can post your own notification here if needed
        // For example: NotificationCenter.default.post(name: .networkStatusChanged, object: nil)
    }

    func isConnectedToNetwork() -> Bool {
        // Check if reachability is initialized
        guard reachability != nil else {
            return false
        }
        
        return reachability.connection != .none
    }
    
    func currentConnectionType() -> String {
        guard reachability != nil else {
            return "Unknown"
        }
        
        switch reachability.connection {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .none:
            return "No Connection"
        }
    }

    func showNoInternetAlert(on vc: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "No Internet Connection".localized(),
                message: "Please check your network settings.".localized(),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default) { _ in
                // Navigate to root view controller
                if let navigationController = vc.navigationController {
                    navigationController.popToRootViewController(animated: true)
                } else {
                    // If no navigation controller, dismiss if presented or just close
                    vc.dismiss(animated: true, completion: nil)
                }
            })
            vc.present(alert, animated: true)
        }
    }
    
    deinit {
        if isMonitoring {
            reachability.stopNotifier()
            NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        }
    }
}

// Optional: Add a custom notification name for network status changes
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}
