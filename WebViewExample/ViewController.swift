//
//  ViewController.swift
//  WebViewExample
//
//  Created by Kocsis Olivér on 29/02/2024.
//

import UIKit
import WebKit

//MARK: - Load Url In Webview
extension WKWebView {
    func loadUrl(string: String) {
        if let url = URL(string: string) {
            load(URLRequest(url: url))
        }
    }
}

class ViewController: UIViewController {
    
    //MARK: Declare IBOutlets
    @IBOutlet var webView : WKWebView!
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var layoutTextField: NSLayoutConstraint!
    
    var myActivityIndicator = UIActivityIndicatorView()
    
    
    //Mark: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchButton.layer.cornerRadius = 12
        searchButton.clipsToBounds = true
        
        btnBack.layer.cornerRadius = 15
        btnNext.clipsToBounds = true
        
        btnNext.layer.cornerRadius = 15
        btnNext.clipsToBounds = true
        
        //MARK: - Create Custom ActivityIndicator
        myActivityIndicator.center = self.view.center
        myActivityIndicator.style = .medium
        view.addSubview(myActivityIndicator)
        
        //Adding observer for show loading indicator
        webView.addObserver(self, forKeyPath:#keyPath(WKWebView.isLoading), options: .new, context: nil)
        searchTextField.text = "https://www.w3schools.com/tags/tryit.asp?filename=tryhtml5_a_download"
        
        webView.navigationDelegate = self
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
    }
    
    private func deleteAllCache() async {
        let websiteDataTypes = Set([WKWebsiteDataTypeDiskCache,
                                    WKWebsiteDataTypeOfflineWebApplicationCache,
                                    WKWebsiteDataTypeMemoryCache,
                                    WKWebsiteDataTypeLocalStorage,
                                    WKWebsiteDataTypeCookies,
                                    WKWebsiteDataTypeSessionStorage,
                                    WKWebsiteDataTypeIndexedDBDatabases,
                                    WKWebsiteDataTypeWebSQLDatabases,
                                    WKWebsiteDataTypeFetchCache, //(iOS 11.3, *)
                                    WKWebsiteDataTypeServiceWorkerRegistrations,
                                   ])
        let alertController = UIAlertController(title: "Deleting these",
                                                message: """
        DiskCache,
        OfflineWebApplicationCache,
        MemoryCache,
        LocalStorage,
        Cookies,
        SessionStorage,
        IndexedDBDatabases,
        WebSQLDatabases,
        FetchCache,
        ServiceWorkerRegistrations,
""",
                                                preferredStyle: .alert)
        let proceed = await withCheckedContinuation { continuation in
            alertController.addAction(
                UIAlertAction(
                    title: "Ok",
                    style: .default,
                    handler: { _ in
                        continuation.resume(returning: true)
                        
                    }
                )
            )
            alertController.addAction(
                UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: { _ in
                        continuation.resume(returning: false)
                    }
                )
            )
            present(alertController, animated: true)
        }
        
        if proceed {
            let date = Date(timeIntervalSince1970: 0)
            await WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes,
                                                          modifiedSince: date)
        }
    }
    
    @IBAction func flushCache(_ sender: UIButton) {
        Task {
            await deleteAllCache()
        }

    }
    
    //Mark: Search Using google query url
    @IBAction func btnSearchAction(_ sender: UIButton) {
        func searchTextOnGoogle(text: String){
            let textComponent = text.components(separatedBy: " ")
            let searchString = textComponent.joined(separator: "+")
            let url = URL(string: "https://www.google.com/search?q=" + searchString)
            let urlRequest = URLRequest(url: url!)
            webView.load(urlRequest)
        }
        if let urlString = searchTextField.text{
            if urlString.starts(with: "http://") || urlString.starts(with: "https://"){
                webView.loadUrl(string: urlString)
            }else if urlString.contains("www"){
                webView.loadUrl(string: "http://\(urlString)")
            }else{
                searchTextOnGoogle(text: urlString)
            }
        }
    }
    
    
    //Mark: Go previous page of Webview
    @IBAction func btnBackAction(_ sender: UIButton) {
        webView.goBack()
    }
    
    //Mark: Go next page of Webview
    @IBAction func btnNextAction(_ sender: Any) {
        webView.goForward()
    }
    
    
    //MARK: - ActivityIndicator StartAnimate And StopAnimate
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading"{
            if webView.isLoading{
                myActivityIndicator.startAnimating()
                myActivityIndicator.isHidden = false
            }else{
                myActivityIndicator.stopAnimating()
            }
        }
    }
    
    func share(url: URL) {
        let sharedObjects = [
            url as AnyObject,
        ]
        let activityViewController = UIActivityViewController(
            activityItems: sharedObjects,
            applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = self.view

//        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook,UIActivityType.postToTwitter,UIActivityType.mail]

        self.present(activityViewController, animated: true, completion: nil)

    }
}

extension ViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
        } else {
            decisionHandler(.allow, preferences)
        }
        
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        download.delegate = self
    }

    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        download.delegate = self
    }
}

extension ViewController: WKDownloadDelegate {
    
    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let fileUrl = documentDirectory.appendingPathComponent(
            "\(suggestedFilename)",
            isDirectory: false
        )
        let alertController = UIAlertController(
            title: "What do we do now?",
            message: "",
            preferredStyle: .alert)
        
        let shareOrLoad = await withCheckedContinuation { continuation in
            alertController.addAction(
                UIAlertAction(
                    title: "Share",
                    style: .default,
                    handler: { _ in
                        continuation.resume(returning: true)
                        
                    }
                )
            )
            alertController.addAction(
                UIAlertAction(
                    title: "Load",
                    style: .default,
                    handler: { _ in
                        continuation.resume(returning: false)
                    }
                )
            )
            present(alertController, animated: true)
        }
        
        
        if shareOrLoad {
            share(url: fileUrl)
        } else {
            webView.load(URLRequest(url: fileUrl))
        }
        
        return fileUrl
    }
    
    
}
