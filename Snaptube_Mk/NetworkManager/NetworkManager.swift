//
//  NetworkManager.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import Foundation
import Alamofire
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    // MARK: - Base URLs
    private let baseProxyURL = "https://api-livevideocall.7seasol.in/proxy?url="
    private let photEnhanceBaseURL = "https://fantasybooth.ai/restore-photo/web/api/"
    private let enhanceUploadUrl = "restore.php"
    private let enhanceResultUrl = "replicate_result_detail.php"
    
    private let headers: HTTPHeaders = [
        "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmZmNlOWE0MGFmNTU5MDM5N2JiYjZjMWIwMGZjOGUxYyIsIm5iZiI6MTc0NjU5Njk0MC41NDIsInN1YiI6IjY4MWFmNDRjYWNkYTE2YzMyNjg1MDhhYyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.p-W6BpCTbQXniMiNOYcKHbuOYjsLoBHy7BdcKvrkbiI",
        "accept": "application/json"
    ]
    
    // MARK: - Get Region Helper
    private func getRegion() -> String {
        return AppStorage.get(forKey: AppStorage.selectedRegion) as String? ?? "US"
    }
    
    // MARK: - Get Language Helper
    private func getLanguage() -> String {
        if let savedLanguage = AppStorage.get(forKey: AppStorage.selectedLanguage) as String? {
            return mapLanguageToCode(savedLanguage)
        }
        return "en-US"
    }
    
    // MARK: - Map Language to TMDB Code
    private func mapLanguageToCode(_ language: String) -> String {
        switch language {
        case "English": return "en-US"
        case "Spanish": return "es-ES"
        case "Hindi": return "hi-IN"
        case "Danish": return "da-DK"
        case "German": return "de-DE"
        case "Italian": return "it-IT"
        case "Portuguese": return "pt-PT"
        case "Turkish": return "tr-TR"
        default: return "en-US"
        }
    }
    
    // MARK: - Private helper to check internet connection
    private func checkInternetConnection(on vc: UIViewController? = nil, completion: @escaping (Bool) -> Void) {
        if !ReachabilityManager.shared.isConnectedToNetwork() {
            if let vc = vc {
                DispatchQueue.main.async {
                    ReachabilityManager.shared.showNoInternetAlert(on: vc)
                }
            }
            completion(false)
        } else {
            completion(true)
        }
    }
    
    // MARK: - Image Upload API
    func uploadImage(_ image: UIImage,
                    countryId: String = "in",
                    on viewController: UIViewController? = nil,
                    completion: @escaping (Result<(id: String, uid: String), Error>) -> Void) {
        
        // Check internet connection
        checkInternetConnection(on: viewController) { [weak self] isConnected in
            guard isConnected else {
                completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])))
                return
            }
            
            guard let self = self else { return }
            
            guard let url = URL(string: self.photEnhanceBaseURL + self.enhanceUploadUrl) else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL"])))
                return
            }
            
            let boundary = UUID().uuidString
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            let boundaryPrefix = "--\(boundary)\r\n"
            
            // Add country_id parameter
            body.append(boundaryPrefix.data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"country_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(countryId)\r\n".data(using: .utf8)!)
            
            // Add image data
            if let imageData = image.pngData() {
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"image\"; filename=\"filename\(Date().timeIntervalSince1970).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let id = "\(json["id"] ?? "")"
                        let uid = "\(json["uid"] ?? "")"
                        
                        if !id.isEmpty && !uid.isEmpty {
                            completion(.success((id: id, uid: uid)))
                        } else {
                            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Check Processing Status
    func checkImageProcessingStatus(id: String,
                                  uid: String,
                                  on viewController: UIViewController? = nil,
                                  completion: @escaping (Result<(status: String, imageUrl: String, outputUrl: String), Error>) -> Void) {
        
        // Check internet connection
        checkInternetConnection(on: viewController) { [weak self] isConnected in
            guard isConnected else {
                completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])))
                return
            }
            
            guard let self = self else { return }
            
            let url = self.photEnhanceBaseURL + self.enhanceResultUrl
            let parameters: [String: Any] = ["id": id, "uid": uid]
            
            AF.request(url, method: .post, parameters: parameters)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let json):
                        if let responseDict = json as? [String: Any] {
                            let rawImageUrl = "\(responseDict["image"] ?? "")"
                            let rawOutput1Url = "\(responseDict["output_1"] ?? "")"
                            let rawStatus = "\(responseDict["process_status"] ?? "")"
                            
                            let cleanImageUrl = rawImageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                            let cleanOutput1Url = rawOutput1Url.trimmingCharacters(in: .whitespacesAndNewlines)
                            let cleanStatus = rawStatus.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            completion(.success((status: cleanStatus, imageUrl: cleanImageUrl, outputUrl: cleanOutput1Url)))
                        } else {
                            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        }
    }
    
    // MARK: - Download Image
    func downloadImage(from urlString: String,
                      on viewController: UIViewController? = nil,
                      completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        // Check internet connection
        checkInternetConnection(on: viewController) { isConnected in
            guard isConnected else {
                completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])))
                return
            }
            
            guard let url = URL(string: urlString) else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"])))
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])))
                    return
                }
                
                completion(.success(image))
            }.resume()
        }
    }
    
    // MARK: - Fetch Remote Config
    func fetchRemoteConfig(from vc: UIViewController,
                           completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        // Check internet connection
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])))
            return
        }
        
        let urlString = getJSON
        
        AF.request(urlString, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any] {
                        completion(.success(json))
                    } else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format."])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Generic API Call with Internet Check
    func makeRequest<T: Decodable>(url: String,
                                   method: HTTPMethod = .get,
                                   parameters: Parameters? = nil,
                                   headers: HTTPHeaders? = nil,
                                   on viewController: UIViewController? = nil,
                                   completion: @escaping (Result<T, Error>) -> Void) {
        
        // Check internet connection
        checkInternetConnection(on: viewController) { isConnected in
            guard isConnected else {
                completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])))
                return
            }
            
            AF.request(url,
                       method: method,
                       parameters: parameters,
                       headers: headers ?? self.headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let result):
                        completion(.success(result))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        }
    }
}
