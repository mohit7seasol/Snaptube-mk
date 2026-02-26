//
//  FavouriteModel.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 25/11/25.
//

import Foundation
import Photos

class FavoritesManager {
    static let shared = FavoritesManager()
    private let favoritesKey = "favoriteAssets"
    
    private init() {}
    
    // MARK: - Save Favorite
    func addToFavorites(asset: PHAsset) {
        var favorites = getFavorites()
        let assetIdentifier = asset.localIdentifier
        
        // Check if already exists
        if !favorites.contains(assetIdentifier) {
            favorites.append(assetIdentifier)
            saveFavorites(favorites)
        }
    }
    
    // MARK: - Remove Favorite
    func removeFromFavorites(asset: PHAsset) {
        var favorites = getFavorites()
        let assetIdentifier = asset.localIdentifier
        
        if let index = favorites.firstIndex(of: assetIdentifier) {
            favorites.remove(at: index)
            saveFavorites(favorites)
        }
    }
    
    // MARK: - Check if Favorite
    func isFavorite(asset: PHAsset) -> Bool {
        let favorites = getFavorites()
        return favorites.contains(asset.localIdentifier)
    }
    
    // MARK: - Get All Favorites
    func getFavorites() -> [String] {
        return UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }
    
    // MARK: - Get Favorite Assets
    func getFavoriteAssets(from assets: [PHAsset]) -> [PHAsset] {
        let favorites = getFavorites()
        return assets.filter { favorites.contains($0.localIdentifier) }
    }
    
    // MARK: - Private Methods
    private func saveFavorites(_ favorites: [String]) {
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
        UserDefaults.standard.synchronize()
    }
}
