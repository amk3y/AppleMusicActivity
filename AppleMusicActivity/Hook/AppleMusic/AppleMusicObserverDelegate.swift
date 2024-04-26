//
//  AppleMusicObserverDelegate.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2024/4/25.
//

import Foundation



public protocol AppleMusicObserverDelegate: NSObjectProtocol{

    
    func observer(didPlayerUpdated state: AppleMusicPlayerState, track: AppleMusicTrack?)
    
    func observer(didIdleConfirm state: AppleMusicPlayerState, track: AppleMusicTrack)
    
}
