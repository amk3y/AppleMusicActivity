//
//  MenuBarView.swift
//  AppleMusicActivity
//
//  Created by amk3y on 2022/11/25.
//

import Foundation
import SwiftUI

struct MenuBarView : View{
    
    var body: some View{
        VStack{
            Image(systemName: "music.note.tv")
                .font(.system(size: 64))
            
            Text("Apple Music Activity")
                .padding([.top], 2.5)
                .padding([.bottom], 1)
                .font(.system(size: 16))
                .bold()
            Text("</> by amk3y with <3")
                .font(.system(size: 12))
                .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.69))
                .padding([.bottom], 20)
            
            Button("Quit") {
                () -> Void in
                exit(0)
            }
            .keyboardShortcut("Q")
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
            
        }
        .padding()

    }
}


struct MenuBarView_Preview : PreviewProvider{
    
    static var previews: some View{
        MenuBarView()
    }
    
}
