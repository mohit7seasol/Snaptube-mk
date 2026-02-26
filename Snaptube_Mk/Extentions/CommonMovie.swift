//
//  Common.swift
//  Movie3App
//
//  Created by DREAMWORLD on 22/09/25.
//

import Foundation
import UIKit

class HelperManager {
    static func configureNavigation(for vc: UIViewController,
                                    backImageName: String,
                                    navTitle: String) {
        // Title (center aligned) with white color
        let titleLabel = UILabel()
        titleLabel.text = navTitle
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .white // White color
        titleLabel.textAlignment = .center
        vc.navigationItem.titleView = titleLabel
        
        // Configure back button for the NEXT view controller
        let backImage = UIImage(named: backImageName)?.withRenderingMode(.alwaysOriginal)
        
        // Set the back indicator images on the navigation bar
        vc.navigationController?.navigationBar.backIndicatorImage = backImage
        vc.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        
        // Remove back button title - MULTIPLE APPROACHES FOR BETTER RELIABILITY
        
        // Approach 1: Empty back bar button item (for next screen)
        vc.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )
        
        // Approach 2: iOS 14+ method (for current screen)
        if #available(iOS 14.0, *) {
            vc.navigationItem.backButtonDisplayMode = .minimal
        }
        
        // Approach 3: Set empty title for back button
        vc.navigationItem.backButtonTitle = ""
        
        // Additional styling to ensure white elements
        vc.navigationController?.navigationBar.tintColor = .white
        vc.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Force back button title to be empty for the current screen too
        vc.navigationController?.navigationBar.topItem?.backButtonTitle = ""
    }
    
    static func playVideoFromYoutube(videoKey: String) {
        let appURL = URL(string: "youtube://\(videoKey)")!
        let webURL = URL(string: "https://www.youtube.com/watch?v=\(videoKey)")!
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
    static func shareYoutubeVideo(videoKey: String?, from vc: UIViewController) {
        guard let key = videoKey, !key.isEmpty else {
            print("⚠️ No valid YouTube key found for sharing.")
            return
        }

        let videoURL = "https://www.youtube.com/watch?v=\(key)"
        let activityVC = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = vc.view  // for iPad support
        
        vc.present(activityVC, animated: true, completion: nil)
    }
    static func shareMovieTrailer(movieName: String, posterPath: String?, videoKey: String?, from vc: UIViewController) {
        guard let key = videoKey, !key.isEmpty else {
            print("⚠️ No valid YouTube key found for sharing.")
            return
        }
        
        let videoURL = "https://www.youtube.com/watch?v=\(key)"
        let posterURL = posterPath.map { "https://image.tmdb.org/t/p/w500\($0)" } ?? ""
        
        // Create a comprehensive sharing message
        var shareItems: [Any] = []
        
        // Add movie name
        shareItems.append("🎬 \(movieName)")
        
        // Add trailer URL
        shareItems.append(videoURL)
        
        // Add poster image URL if available
        if !posterURL.isEmpty {
            shareItems.append("📸 Movie Poster: \(posterURL)")
        }
        
        let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = vc.view  // for iPad support
        
        vc.present(activityVC, animated: true, completion: nil)
    }

    private static func presentShareSheetYoutube(from vc: UIViewController, with items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad support
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = vc.view
            popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        vc.present(activityVC, animated: true)
    }

    private static func presentShareSheetTVShow(from vc: UIViewController, with items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad support
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = vc.view
            popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        vc.present(activityVC, animated: true)
    }

    // MARK: - Helper Function
    private static func presentShareSheet(from vc: UIViewController, with items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = vc.view
        vc.present(activityVC, animated: true, completion: nil)
    }
    static func showToast(message: String, isSuccess: Bool, vc: UIViewController) {
        // Remove existing toasts from the provided view controller's view
        vc.view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        
        let toastContainer = UIView()
        toastContainer.tag = 999
        toastContainer.backgroundColor = #colorLiteral(red: 0.07726272196, green: 0.07726272196, blue: 0.07726272196, alpha: 1)
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 8
        toastContainer.clipsToBounds = true
        
        let toastLabel = UILabel()
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        
        toastContainer.addSubview(toastLabel)
        vc.view.addSubview(toastContainer)
        
        // Calculate required width based on text
        let maxWidth = vc.view.frame.width - 80 // 40 padding on each side
        let textSize = toastLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        let requiredWidth = min(textSize.width + 32, maxWidth) // 16 padding on each side
        
        // Setup constraints
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Center the toast horizontally with dynamic width
            toastContainer.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            toastContainer.widthAnchor.constraint(equalToConstant: requiredWidth),
            toastContainer.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Label constraints
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -16),
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 12),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -12)
        ])
        
        // Animate in and out
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn) {
            toastContainer.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
                toastContainer.alpha = 0.0
            } completion: { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
