//
//  AppleMusicObserver.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2022/11/28.
//

import Foundation
import AppKit

public enum AppleMusicPlayerState: Int{
    case PLAYING = 10
    case STOPPED = 0
    case PAUSED = 20
    case FAST_FORWARDING = 30
    case REWINDING = 40
}

public class AppleMusicObserver: ObservableObject{
    
    
    private static let script =
    """
        set databaseId to null
        set trackName to null
        set trackArtist to null
        set trackArtwork to null
        set trackDuration to 0
        set trackPosition to 0
        set playerState to null
        set albumName to null

        tell application "Music"
            try
                set databaseId to database ID of current track
                set trackName to name of current track
            end try
            try
                set albumName to album of current track
            end try
            try
                set trackArtist to artist of current track
            end try
            try
                set trackArtwork to data of artwork 1 of current track
            end try
            try
                set trackPosition to player position
                set trackDuration to duration of current track
            end try
            try
                if (player state = playing) then
                    set playerState to 10
                else if (player state = paused) then
                    set playerState to 20
                else if (player state = stopped) then
                    set playerState to 0
                else if (player state = fast forwarding) then
                    set playerState to 30
                else
                    set playerState to 40
                end if
            end try
        end tell

        return {databaseId, trackName, trackArtist, trackArtwork, trackPosition, trackDuration, playerState, albumName}
    """
    
    public static let shared: AppleMusicObserver = AppleMusicObserver()
    
    let timer: DispatchSourceTimer
    let dispatchQueue: DispatchQueue
    weak var delegate: AppleMusicObserverDelegate?
        
    var track: AppleMusicTrack?
    var playerState: AppleMusicPlayerState = .STOPPED
    
    init(){
        dispatchQueue = DispatchSerialQueue(label: "AppleMusicObserverDispatchQueue")
        timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
        timer.setEventHandler { self.run() }
        
        AppleMusicActivityApp.logger.info("[AppleMusicObserver] Initialized")
    }
    
    public func startUpdating(){
        timer.schedule(deadline: DispatchTime.now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.activate()
        AppleMusicActivityApp.logger.info("[AppleMusicObserver] Start updating")
    }
    
    public func stopUpdating(){
        timer.suspend()
        AppleMusicActivityApp.logger.info("[AppleMusicObserver] Requested to stop updating")
    }
    
    private func wrapScript(script: String) -> String{
        return """
        tell application "System Events"
            set launched to (name of processes) contain "Music"
                if launched then
                    \(script)
                else
                    return null
                end if
        end tell
        """
    }
    
    func handleScriptFailure(_ errorInfo: NSDictionary?){
        handleUpdate(nil, .STOPPED)
    }
    
    func handleUpdate(_ newTrack: AppleMusicTrack?, _ state: AppleMusicPlayerState){
        self.track = newTrack
        self.playerState = state
        delegate?.observer(didPlayerUpdated: state, track: track)
    }
    
    
    func run(){
        let script = NSAppleScript(source: wrapScript(script: AppleMusicObserver.script))
        var errorInfo: NSDictionary?
        let result = script?.executeAndReturnError(&errorInfo)
        
        guard let eventDescriptor = result?.coerce(toDescriptorType: typeAEList)
        else{
            handleScriptFailure(errorInfo)
            return
        }
        
        let newState = AppleMusicPlayerState(
            rawValue: Int(eventDescriptor.atIndex(7)?.int32Value ?? Int32(AppleMusicPlayerState.STOPPED.rawValue)))
        ?? AppleMusicPlayerState.STOPPED

        if(newState != playerState && newState == .STOPPED){
            delegate?.observer(didPlayerUpdated: .STOPPED, track: nil)
            playerState = .STOPPED
            return
        }
        
        var artist = eventDescriptor.atIndex(3)?.stringValue
        if(artist != nil && artist!.isEmpty){
            artist = nil
        }
        
        guard let databaseId = eventDescriptor.atIndex(1)?.int32Value
        else{
            handleScriptFailure(errorInfo)
            return
        }
        
        guard let name = eventDescriptor.atIndex(2)?.stringValue
        else {
            handleScriptFailure(errorInfo)
            return
        }
        
        let newTrack: AppleMusicTrack = AppleMusicTrack(
            databaseId: databaseId,
            name: name,
            artist: artist,
            album: eventDescriptor.atIndex(8)!.stringValue,
            artwork: eventDescriptor.atIndex(4)!.data,
            duration: eventDescriptor.atIndex(6)!.doubleValue,
            position: eventDescriptor.atIndex(5)!.doubleValue
        )
        
        if let currentTrack = self.track{
            if(currentTrack.databaseId != newTrack.databaseId){
                AppleMusicActivityApp.logger.info("[AppleMusicObserver] Track has been updated \(currentTrack.databaseId) -> \(newTrack.databaseId)")
                handleUpdate(newTrack, newState)
                return
            }
            
            if(newState != playerState){
                AppleMusicActivityApp.logger.info("[AppleMusicObserver] Player State has been changed \(self.playerState.rawValue) -> \(newState.rawValue)")
                handleUpdate(newTrack, newState)
                return
            }
            
            if(abs(currentTrack.endTimestamp - newTrack.endTimestamp) > 3 && newState == .PLAYING){
                AppleMusicActivityApp.logger.info("[AppleMusicObserver] Timeline is out of sync {current=\(currentTrack.startTimestamp), recorded=\(newTrack.startTimestamp)}")
                handleUpdate(newTrack, newState)
            }
            
            return
        }
        
        AppleMusicActivityApp.logger.info("[AppleMusicObserver] Track has been updated \(newTrack.databaseId)")
        handleUpdate(newTrack, newState)
    }
}
