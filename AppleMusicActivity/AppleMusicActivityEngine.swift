//
//  AppleMusicActivity.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2024/4/25.
//

import Foundation
import AppKit
import CryptoKit

import Firebase
import FirebaseCore
import FirebaseStorage

import DiscordRPC


public class AppleMusicActivityEngine: NSObject, AppleMusicObserverDelegate{
    
    public static let shared = AppleMusicActivityEngine()
    
    private var isActivitySet: Bool = false
    
    public func startUpdating(){
        AppleMusicObserver.shared.delegate = self
    }
    
    public func observer(didIdleConfirm state: AppleMusicPlayerState, track: AppleMusicTrack) {
        
    }
    
    public func observer(didPlayerUpdated state: AppleMusicPlayerState, track: AppleMusicTrack?) {
        if(track == nil || state == AppleMusicPlayerState.STOPPED){
            if (isActivitySet){
                isActivitySet = false
                DiscordAPIHandler.shared.clearActivity()
            }
            return
        }
        
        var artworkData: Data? = nil
        let originArtworkData = track!.artwork?.tiffRepresentation
        
        if(originArtworkData != nil){
            let bitmapRep = NSBitmapImageRep(data: originArtworkData!)
            artworkData = bitmapRep?.representation(using: .jpeg, properties: [:])
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        if (artworkData == nil){
            let artwork = storageRef.child(AppleMusicActivityApp.DEFAULT_ARTWORK)
            artwork.downloadURL { (url: URL?, error: Error?) in
                if (error != nil){
                    AppleMusicActivityApp.logger.info("[AppleMusicActivityEngine] Unable to fetch default artwork \(error)")
                    return
                }
                track!.artworkUrl = url?.absoluteString
                DiscordAPIHandler.shared.updateActivity(track: track!, state: state)
                self.isActivitySet = true
            }
            return
        }
        
        let hash = SHA256
            .hash(data: artworkData!)
            .map {String(String(format: "%02x", $0))}
            .joined()
        
        //let artworkDirectoryRef = storageRef.child(AppleMusicActivityApp.ARTWORK_DIRECTORY)
        let artworkDirectoryRef = storageRef
        let artworkRef = artworkDirectoryRef.child("\(hash).jpg")
        
        Task{ [artworkData] in
            var remoteMetadata: StorageMetadata?
            do {
                remoteMetadata = try await artworkRef.getMetadata()
            } catch {
                let exception = error as! StorageError
                switch exception{
                case .objectNotFound:
                    break
                default:
                    await AppleMusicActivityApp.logger.info("[AppleMusicActivityEngine] Unable to fetch remote metadata: \(exception)")
                    break
                }
            }
            
            if(remoteMetadata == nil){
                do {
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    let newMetadata = try await artworkRef.putDataAsync(artworkData!, metadata: metadata)
                } catch {
                    let exception = error as NSError
                    let firebaseErrorCode = StorageErrorCode(rawValue: exception.code)
                    switch firebaseErrorCode{
                    default:
                        await AppleMusicActivityApp.logger.info("[AppleMusicActivityEngine] Unable to upload artwork: \(exception)")
                        break
                    }
                }
            }else {
                await AppleMusicActivityApp.logger.info("[AppleMusicActivityEngine] Artwork cache is found")
            }
            do {
                let url = try await artworkRef.downloadURL()
                await AppleMusicActivityApp.logger.info("[AppleMusicActivityEngine] Fetched artwork url: \(url.absoluteString)")
                track!.artworkUrl = url.absoluteString
                DiscordAPIHandler.shared.updateActivity(track: track!, state: state)
                self.isActivitySet = true
            } catch{
                await AppleMusicActivityApp.logger.info("[AppleMusicActivityEngine] Unable to fetch artwork url: \(error)")
            }
            
        }
    }
    
}
