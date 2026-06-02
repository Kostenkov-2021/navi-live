import MediaPlayer

final class HeadphoneRemoteControlService {
  private var playTarget: Any?
  private var pauseTarget: Any?
  private var toggleTarget: Any?
  private var onCommand: (() -> Void)?
  private var isActive = false

  func update(isEnabled: Bool, isNavigationActive: Bool, onCommand: @escaping () -> Void) {
    self.onCommand = onCommand
    if isEnabled && isNavigationActive {
      activate()
    } else {
      deactivate()
    }
  }

  func deactivate() {
    guard isActive else { return }
    let center = MPRemoteCommandCenter.shared()
    if let playTarget {
      center.playCommand.removeTarget(playTarget)
    }
    if let pauseTarget {
      center.pauseCommand.removeTarget(pauseTarget)
    }
    if let toggleTarget {
      center.togglePlayPauseCommand.removeTarget(toggleTarget)
    }
    playTarget = nil
    pauseTarget = nil
    toggleTarget = nil
    center.playCommand.isEnabled = false
    center.pauseCommand.isEnabled = false
    center.togglePlayPauseCommand.isEnabled = false
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    isActive = false
  }

  private func activate() {
    guard !isActive else { return }
    let center = MPRemoteCommandCenter.shared()
    center.playCommand.isEnabled = true
    center.pauseCommand.isEnabled = true
    center.togglePlayPauseCommand.isEnabled = true
    playTarget = center.playCommand.addTarget { [weak self] _ in
      self?.onCommand?()
      return .success
    }
    pauseTarget = center.pauseCommand.addTarget { [weak self] _ in
      self?.onCommand?()
      return .success
    }
    toggleTarget = center.togglePlayPauseCommand.addTarget { [weak self] _ in
      self?.onCommand?()
      return .success
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: "Navi Live",
      MPMediaItemPropertyArtist: "Walking guidance",
      MPNowPlayingInfoPropertyPlaybackRate: 0.0,
    ]
    isActive = true
  }
}
