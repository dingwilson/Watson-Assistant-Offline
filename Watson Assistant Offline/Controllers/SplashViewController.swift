//
//  SplashViewController.swift
//  Watson Assistant Offline
//
//  Created by Wilson on 7/12/18.
//  Copyright © 2018 Wilson Ding. All rights reserved.
//

import UIKit
import SwiftVideoBackground

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        try? VideoBackground.shared.play(view: self.view, videoName: "background", videoType: "mp4", isMuted: true, darkness: 0.2, willLoopVideo: true, setAudioSessionAmbient: true)
    }

}
