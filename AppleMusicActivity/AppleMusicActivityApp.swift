//
//  AppleMusicActivityApp.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2024/4/26.
//

import SwiftUI
import OSLog

import Firebase

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        FirebaseApp.configure()
        
        guard let applicationId = (Bundle.main.infoDictionary?["DISCORD_APPLICATION_ID"] as? String)?
                .replacingOccurrences(of: "\\", with: "")
                .replacing("\"", with: "")
        else{
            AppleMusicActivityApp.logger.info("[AppleMusicActivityApp] Discord Application ID is not found")
            exit(0)
        }
        
        guard let applicationSecret = (Bundle.main.infoDictionary?["DISCORD_APPLICATION_SECRET"] as? String)?
                .replacingOccurrences(of: "\\", with: "")
                .replacing("\"", with: "")
        else{
            AppleMusicActivityApp.logger.info("[AppleMusicActivityApp] Discord Application secret is not found")
            exit(0)
        }
        
        
        DiscordAPIHandler.shared.configure(applicationId: applicationId, secret: applicationSecret)
        AppleMusicActivityEngine.shared.startUpdating()
        AppleMusicObserver.shared.startUpdating()
    }
}


@main
struct AppleMusicActivityApp: App {
    public static let ARTWORK_DIRECTORY = "artwork"
    public static let DEFAULT_ARTWORK = "applemusic_default.jpg"
    
    public static let logger = Logger()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var menuBarExtraShown = true

    init(){}

    var body: some Scene {
        MenuBarExtra(isInserted: $menuBarExtraShown){
            MenuBarView()
        } label: {
            Label("Apple Music Activity", systemImage: "music.note.tv")
        }
        .menuBarExtraStyle(.window)
        
    }
}
