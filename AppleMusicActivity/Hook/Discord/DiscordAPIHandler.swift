//
//  DiscordAPIHandler.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2022/11/25.
//

import Foundation
import DiscordRPC

public class DiscordAPIHandler{
    public static let shared = DiscordAPIHandler()
    
    
    private var discordRpc: DiscordRPC?
    private var initialized: Bool
    
    public init(){
        initialized = false
    }
    
    
    public func configure(applicationId: String, secret: String){
        self.discordRpc = DiscordRPC(clientID: applicationId, clientSecret: secret)
        
        if let discordCore = self.discordRpc{
            discordCore.onConnect { rpc, eventReady in
                AppleMusicActivityApp.logger.info("[DiscordAPI] Connected to Discord RPC Host")
                self.initialized = true
            }
            
            do {
                try discordCore.connect()
            } catch {
                AppleMusicActivityApp.logger.info("[DiscordAPI] An error occurred while connecting to Discord RPC Host \(error)")
            }
        }
        
    }
    
    public func clearActivity(){
        guard let discord = self.discordRpc
        else {
            return
        }
        
        
        if(!initialized){
            AppleMusicActivityApp.logger.info("[DiscordAPI] Activity Clear Call is cancelled due to initialization faillure")
            return
        }
    
        do {
            let response = try discord.clearActivity()
            AppleMusicActivityApp.logger.info("[DiscordAPI] Activity Cleared: \(response)")
        } catch{
            AppleMusicActivityApp.logger.info("[DiscordAPI] Unable to clear activity: \(error)")
        }
    }
    
    public func updateActivity(track: AppleMusicTrack, state: AppleMusicPlayerState){
        if(!initialized){
            AppleMusicActivityApp.logger.info("[DiscordAPI] Activity Update Call is cancelled due to initialization faillure")
            return
        }
        
        guard let discord = self.discordRpc
        else {
            return
        }
        
        let now = Date.now.timeIntervalSince1970
        let timestamp = Timestamps(start: Int(now - track.position), end: Int(now + track.duration - track.position))
        let assets = Assets(largeImage: track.artworkUrl, largeText: track.album ?? "Apple Music", smallImage: nil, smallText: nil)
        
        var buttons: [Button] = []
        if(track.album != nil && track.album!.count > 1 && track.album!.count < 32){
            let label = "\(track.album!) on Apple Music"
            buttons.append(Button(label: label.count >= 32 ? track.album! : label, url: "https://music.apple.com/tw/browse"))
        }
        buttons.append(Button(label: "Activity </> by amk3y", url: "https://amk3y.net"))
        
        let trackName = track.name.count <= 1 ? "\(track.name)  " : track.name
        
        let activity: Activity
        if let artist = track.artist{
            activity = Activity(
                type: .Listening,
                timestamps: state == .PLAYING ? timestamp : nil,
                state: artist.count <= 1 ? "\(artist)  " : artist,
                details: trackName,
                assets: assets,
                buttons: buttons
            )
        }else{
            activity = Activity(
                type: .Listening,
                timestamps: state == .PLAYING ? timestamp : nil,
                state: trackName,
                details: nil,
                assets: assets,
                buttons: buttons
            )
        }
        

        
        do {
            let response = try discord.setActivity(activity: activity)
            AppleMusicActivityApp.logger.info("[DiscordAPI] Activity Updated: \(response)")
        } catch{
            AppleMusicActivityApp.logger.info("[DiscordAPI] Unable to update activity: \(error)")
        }
        
    }
    
}

