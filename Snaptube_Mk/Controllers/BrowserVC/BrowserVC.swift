//
//  BrowserVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 26/11/25.
//

import UIKit
import SVProgressHUD

class BrowserVC: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    var urlString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressHUD()
        setupWebView()
        checkInternetAndLoadWebView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Dismiss HUD when leaving the screen
        SVProgressHUD.dismiss()
    }
    
    private func setupProgressHUD() {
        // Configure SVProgressHUD
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMinimumDismissTimeInterval(2.0)
    }
    
    private func setupWebView() {
        // Set web view background color to black
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.delegate = self
        
        // Set the main view background to black
        view.backgroundColor = .black
        
        // For iOS 13+ - set the scroll view background
        if #available(iOS 13.0, *) {
            webView.scrollView.backgroundColor = .black
        }
    }
    
    private func checkInternetAndLoadWebView() {
        // First check internet connectivity using ReachabilityManager
        if !ReachabilityManager.shared.isConnectedToNetwork() {
            showNoInternetAlert()
            return
        }
        
        loadWebView()
    }
    
    private func showNoInternetAlert() {
        // Use ReachabilityManager's alert method
        ReachabilityManager.shared.showNoInternetAlert(on: self)
        
        // Alternatively, show custom alert with retry option
        /*
        let alert = UIAlertController(
            title: "No Internet Connection".localized(),
            message: "Please check your network settings and try again.".localized(),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Retry".localized(), style: .default, handler: { [weak self] _ in
            self?.checkInternetAndLoadWebView()
        }))
        
        present(alert, animated: true, completion: nil)
        */
    }
    
    private func loadWebView() {
        guard let url = URL(string: urlString) else {
            SVProgressHUD.showError(withStatus: "Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper method to handle network retry
    private func retryWebViewLoading() {
        if webView.isLoading {
            webView.stopLoading()
        }
        checkInternetAndLoadWebView()
    }
}

// MARK: - UIWebViewDelegate
extension BrowserVC: UIWebViewDelegate {
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        // Show loading indicator when loading starts
        SVProgressHUD.show(withStatus: "Loading...")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // Hide loading indicator when content is fully loaded
        SVProgressHUD.dismiss()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // Check if error is related to network connectivity
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorTimedOut:
                
                // First check current network status
                if !ReachabilityManager.shared.isConnectedToNetwork() {
                    // Show network error message
                    SVProgressHUD.showError(withStatus: "No Internet Connection")
                    
                    // Dismiss and show retry alert
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        SVProgressHUD.dismiss()
                        self?.showNoInternetAlert()
                    }
                } else {
                    // We have internet but server connection failed
                    SVProgressHUD.showError(withStatus: "Server Connection Failed")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        SVProgressHUD.dismiss()
                    }
                }
                return
                
            default:
                break
            }
        }
        
        // For other errors, show generic error
        SVProgressHUD.showError(withStatus: "Failed to load content")
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            SVProgressHUD.dismiss()
        }
    }
}
