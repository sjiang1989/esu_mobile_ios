//
//  AudioViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/21/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class AudioViewController: UIViewController, AVAudioPlayerDelegate, EllucianMobileLaunchableControllerProtocol {
    
    var module : Module!

    var sliderTimer : Timer?
    var mpArtwork : MPMediaItemArtwork?
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var seeker: UISlider!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var textTextView: UITextView!
    
    @IBOutlet var textLabelBackgroundView: UIView!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var play: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendView("Audio", moduleName: module!.name)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlString = module!.property(forKey: "audio")
        let url = URL(string: urlString!)
        if let url = url {
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            do {
                NotificationCenter.default.addObserver(self, selector:#selector(AudioViewController.itemDidFinishPlaying(_:)), name:NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
                
                sliderTimer = Timer .scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(AudioViewController.updateSlider), userInfo: nil, repeats: true)
                
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                SingletonAVPlayer.shared.player = AVPlayer(playerItem: playerItem)
                SingletonAVPlayer.shared.player?.currentItem?.addObserver(self, forKeyPath: "status", options: ([.new, .initial]), context: nil)
                
               
                if let description = module!.property(forKey: "description") , description.characters.count > 0 {
                    
                    textLabel.text = description
                    textTextView.text = description
                    
                    textTextView.textColor = UIColor.white
                    textTextView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
                    
                    let labelTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AudioViewController.expandText(_:)))
                    labelTapGestureRecognizer.numberOfTapsRequired = 1
                    textLabelBackgroundView.addGestureRecognizer(labelTapGestureRecognizer)
                    
                    let textViewTapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(AudioViewController.expandText(_:)))
                    textViewTapGestureRecognizer.numberOfTapsRequired = 1
                    textTextView.addGestureRecognizer(textViewTapGestureRecognizer)
                    
                    
                } else {
                    textLabelBackgroundView.isHidden = true
                    textLabel.isHidden = true
                }

                if let imageUrl = self.module?.property(forKey: "image") {
                    URLSession.shared.dataTask(with: URL(string: imageUrl)!) { (data, response, error) in
                        if let data = data {
                            DispatchQueue.main.async {
                                let image = UIImage(data: data)
                                if let image = image {
                                    self.imageView.image = image
                                    self.mpArtwork = MPMediaItemArtwork(image: image)
                                    self.updateNowPlaying()
                                }
                            }
                        }
                    }.resume()
                }
                
                self.title = module!.name
                self.seeker.thumbTintColor = UIColor.primary
                self.seeker.minimumTrackTintColor = UIColor.primary
                
                configureRemoteCommandCenter()

                self.updateNowPlaying()
            } catch let error {
                print (error)
            }
            
        }
    }
    
    func configureRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(self.goPause))
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget(self, action: #selector(self.goPlay))
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget(self, action: #selector(self.goPause))
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(self.togglePlay))
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(self.goForward))
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(self.goBack))

    }

    func updateNowPlaying() {
        
        if let audioPlayer = SingletonAVPlayer.shared.player {
            let playbackDuration = CMTimeGetSeconds(audioPlayer.currentItem!.duration)
            let playbackTime = CMTimeGetSeconds(audioPlayer.currentItem!.currentTime())
            let duration = isPlaying() ? 1.0 : 0.0
            
            if let artwork = self.mpArtwork{
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [ MPMediaItemPropertyArtwork : artwork, MPMediaItemPropertyTitle : module!.name, MPMediaItemPropertyPlaybackDuration:playbackDuration, MPNowPlayingInfoPropertyPlaybackRate: duration, MPNowPlayingInfoPropertyElapsedPlaybackTime: playbackTime ]
                
            } else {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [ MPMediaItemPropertyTitle : module!.name, MPMediaItemPropertyPlaybackDuration:playbackDuration, MPNowPlayingInfoPropertyPlaybackRate: duration, MPNowPlayingInfoPropertyElapsedPlaybackTime: playbackTime ]
            }
        }
    }

    

    
    @IBAction func togglePlay(_ sender: AnyObject) {
        if let _ = SingletonAVPlayer.shared.player {
            if isPlaying() {
                goPause(sender)
            } else {
                goPlay(sender)
            }
        }
    }
    
    func goPlay(_ sender: AnyObject) {
        if let player = SingletonAVPlayer.shared.player {
            sendEventToTracker1(category: .ui_Action, action: .button_Press, label: "Play button pressed", moduleName: self.module?.name)
            player.play()
            playButton.setImage(UIImage(named: "media_pause"), for: UIControlState())
            updateNowPlaying()
        }
    }
    
    func goPause(_ sender: AnyObject) {
        if let player = SingletonAVPlayer.shared.player {
            player.pause()
            playButton.setImage(UIImage(named: "media_play"), for: UIControlState())
            updateNowPlaying()
        }
    }
    
    @IBAction func goBack(_ sender: AnyObject) {
        if let player = SingletonAVPlayer.shared.player {
            let newTime = CMTimeMakeWithSeconds(0, 600)
            player.seek(to: newTime)
            updateSlider()
        }
    }
    @IBAction func goForward(_ sender: AnyObject) {
        if let player = SingletonAVPlayer.shared.player {
            let newTime = CMTimeMakeWithSeconds(durationInSeconds() + 1, 600)
            player.seek(to: newTime)
            updateSlider()
        }
    }
    
    func isPlaying() -> Bool {
        if let player = SingletonAVPlayer.shared.player {
            return player.currentItem != nil && player.rate != 0
        }
        return false
    }
    
    func updateSlider() {
        let duration = durationInSeconds()
        if duration > 0 {
            self.seeker.maximumValue = Float(duration)
            self.seeker.value = Float(currentTimeInSeconds())
            updateNowPlaying()
        } else {
            self.seeker.isEnabled = false
        }
    }
    
    func durationInSeconds() -> Float64 {
        if let currentItem = SingletonAVPlayer.shared.player?.currentItem {
            return CMTimeGetSeconds(currentItem.duration)
        }
        return 0
    }
    
    func currentTimeInSeconds() -> Float64 {
        if let currentItem = SingletonAVPlayer.shared.player?.currentItem {
            return CMTimeGetSeconds(currentItem.currentTime())
        }
        return 0
    }
    
    @IBAction func sliding(_ sender: AnyObject) {
        if let player = SingletonAVPlayer.shared.player {
            
            let newTime = CMTimeMakeWithSeconds(Float64(seeker.value), 600)
            player.seek(to: newTime)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let player = SingletonAVPlayer.shared.player {
            if player.currentItem!.status == .readyToPlay {
                let _ = player.currentItem?.duration
                
                playButton.isEnabled = true
                forwardButton.isEnabled = true
                backButton.isEnabled = true
                seeker.isEnabled = true
                
                updateSlider()
                
                if let currentItem = player.currentItem {
                    currentItem.removeObserver(self, forKeyPath: "status")
                }
            } else if player.currentItem!.status == .failed {
                let error = player.currentItem?.error?.localizedDescription
                let alertController = UIAlertController(title: NSLocalizedString("Error Loading Audio", comment: "title when error loading audio"), message: error, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                alertController.addAction(OKAction)
                
                if let currentItem = player.currentItem {
                    currentItem.removeObserver(self, forKeyPath: "status")
                }
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func itemDidFinishPlaying(_ sender: AnyObject) {
        if let player = SingletonAVPlayer.shared.player {
            playButton.setImage(UIImage(named: "media_play"), for: UIControlState())
            let newTime = CMTimeMakeWithSeconds(0, 1)
            player.seek(to: newTime)
            updateSlider()
        }
    }
    
    override public var canBecomeFirstResponder: Bool { return true }

    func expandText(_ sender: AnyObject) {
        if textLabelBackgroundView.isHidden { //shrink
            textLabel.isHidden = false
            textLabelBackgroundView.isHidden = false
            textTextView.isHidden = true
        } else { //grow
            textLabel.isHidden = true
            textLabelBackgroundView.isHidden = true
            textTextView.isHidden = false
        }
    }
}
