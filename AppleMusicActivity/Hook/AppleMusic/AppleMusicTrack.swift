//
//  AppleMusicTrack.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2022/11/29.
//

import Foundation
import AppKit
public class AppleMusicTrack {
    
    
    let databaseId: Int32
    let name: String
    let artist: String?
    let album: String?
    let artwork: NSImage?
    let duration: Double
    let position: Double
    let timestamp: Double
    
    public var artworkUrl: String?

    init(databaseId: Int32, name: String, artist: String?, album: String?, artwork: NSImage?, duration: Double, position: Double) {
        self.databaseId = databaseId
        self.name = name
        self.artist = artist
        self.artwork = artwork
        if let isAlbumNameEmpty = album?.isEmpty{
            self.album = isAlbumNameEmpty ? nil : album
        }else {
            self.album = album
        }
        self.duration = duration
        self.position = position
        self.timestamp = Date.now.timeIntervalSince1970
    }
    
    init(databaseId: Int32, name: String, artist: String?, album: String?, artwork: Data?, duration: Double, position: Double) {
        self.databaseId = databaseId
        self.name = name
        self.artist = artist
        if let isAlbumNameEmpty = album?.isEmpty{
            self.album = isAlbumNameEmpty ? nil : album
        }else {
            self.album = album
        }
        self.artwork = artwork == nil ? nil : NSImage(data: artwork!)
        self.duration = duration
        self.position = position
        self.timestamp = Date.now.timeIntervalSince1970
    }
}
