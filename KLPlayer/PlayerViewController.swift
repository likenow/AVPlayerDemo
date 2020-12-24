//
//  PlayerViewController.swift
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

import Foundation
import SnapKit

@objc(PlayerViewController)
class PlayerViewController: UIViewController {
    ///btn
    let btnPause = UIButton(type: .system)
    let btnPlay = UIButton(type: .system)
    let btnDismiss = UIButton(type: .system)
    
    let adContentView = UIView(frame: .zero)
    let w = UIScreen.main.bounds.width
    let h = 400
    let videoUrl = URL.init(string: "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319222227698228.mp4")!
    let firstImageUrl = "https://scpic.chinaz.net/files/pic/pic9/202012/bpic22060.jpg"
    lazy var videoPlayer = KLVideoController.init(videoURL: videoUrl, videoFirstFrameImageURL:firstImageUrl , viewFrame: CGRect.init(x: 0, y: 0, width: Int(w), height: h), downloadWhilePlay: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.adContentView)
        self.view.backgroundColor = .white
        
        self.adContentView.backgroundColor = .yellow
        self.adContentView.snp.makeConstraints {
            $0.top.equalTo(self.view)
            $0.width.equalTo(self.view)
            $0.height.equalTo(400)
        }
        
        self.videoPlayer.isLooping = false
        self.videoPlayer.videoPlayer.muted = true
        self.videoPlayer.playerView.isEndByFirstFrameImage = true
        self.adContentView.addSubview(self.videoPlayer.playerView)
        
        self.view.addSubview(self.btnPause)
        self.btnPause.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 128, height: 32))
            $0.top.equalTo(self.adContentView.snp.bottom).offset(64)
            $0.left.equalTo(self.view)
        }
        self.btnPause.setTitle("Pause", for: .normal)
        self.btnPause.addTarget(self, action: #selector(handlePause(_:)), for: .touchUpInside)
        
        self.view.addSubview(self.btnPlay)
        self.btnPlay.snp.makeConstraints {
            $0.size.equalTo(self.btnPause)
            $0.top.equalTo(self.adContentView.snp.bottom).offset(64)
            $0.left.equalTo(self.btnPause.snp.right)
        }
        self.btnPlay.setTitle("Play", for: .normal)
        self.btnPlay.addTarget(self, action: #selector(handlePlay(_:)), for: .touchUpInside)
        
        self.view.addSubview(self.btnDismiss)
        self.btnDismiss.snp.makeConstraints {
            $0.size.equalTo(self.btnPlay)
            $0.top.equalTo(self.adContentView.snp.bottom).offset(64)
            $0.left.equalTo(self.btnPlay.snp.right)
        }
        self.btnDismiss.setTitle("Dismiss", for: .normal)
        self.btnDismiss.addTarget(self, action: #selector(handleDismiss(_:)), for: .touchUpInside)
    }
    
    @objc func handlePause(_ sender: UIButton) {
        // pause
        self.videoPlayer.videoPlayer.pause()
    }
    
    @objc func handlePlay(_ sender: UIButton) {
        // play
        self.videoPlayer.videoPlayer.play()
    }
    
    @objc func handleDismiss(_ sender: UIButton) {
        // play
        self.dismiss(animated: true)
    }
}
