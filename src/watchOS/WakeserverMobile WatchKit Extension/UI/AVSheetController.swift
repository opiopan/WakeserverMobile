//
//  AVSheetController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/12/17.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch


class AVSheetController: WSPageController, WKCrownDelegate {

    // channel animation related objects
    @IBOutlet var channelGroup: WKInterfaceGroup!
    @IBOutlet var playerGroup: WKInterfaceGroup!
    @IBOutlet var volumeGroup: WKInterfaceGroup!
    @IBOutlet var channelPicker: WKInterfacePicker!
    
    // volume animation related objects
    @IBOutlet var sliderGroup: WKInterfaceGroup!
    @IBOutlet var volumeTapGesture: WKTapGestureRecognizer!
    @IBOutlet var volumeSlider: WKInterfaceSlider!
    @IBOutlet var volumeCircle: WKInterfaceGroup!
    @IBOutlet var volumeBackgroundCircleImage: WKInterfaceImage!
    @IBOutlet var volumeCircleImage: WKInterfaceImage!
    @IBOutlet var volumeSpeakerIcon: WKInterfaceImage!
    private var volumeBackgroundCircleObject: InterfaceCircle!
    private var volumeCircleObject: InterfaceCircle!
    @IBOutlet var assosiativeButtons: WKInterfaceGroup!
    
    // button related objects
    @IBOutlet var playPauseButtonColorChangee: WKInterfaceGroup!
    @IBOutlet var playPauseButtonSizeChangee: WKInterfaceImage!
    @IBOutlet var forwardButtonColorChangee: WKInterfaceGroup!
    @IBOutlet var forwardButtonSizeChangee: WKInterfaceImage!
    @IBOutlet var rewindButtonColorChangee: WKInterfaceGroup!
    @IBOutlet var rewindButtonSizeChangee: WKInterfaceImage!
    @IBOutlet var altForwardButtonSizeChangee: WKInterfaceObject!
    @IBOutlet var altRewindButtonSizeChangee: WKInterfaceObject!
    @IBOutlet var altForwardButtonLabel: WKInterfaceLabel!
    @IBOutlet var altRewindButtonLabel: WKInterfaceLabel!
    private var playPauseButtonAnimation: ButtonAnimation?
    private var forwardButtonAnimation: ButtonAnimation?
    private var rewindButtonAnimation: ButtonAnimation?
    private var altForwardButtonAnimation: ButtonAnimation?
    private var altRewindButtonAnimation: ButtonAnimation?

    private var volumeData : VolumeData?
    
    private var pageData: AVAccessory?

    private typealias GEOMETRY = (
        space: CGFloat,
        channel: CGFloat,
        player: CGFloat,
        volumeCircle: CGFloat,
        volumeSlider: CGFloat,
        assosiativeButtonsNormal: CGFloat,
        assosiativeButtonsExpand: CGFloat
    )

    private var geometry: GEOMETRY!
    
    private let geometryFor42mm: GEOMETRY = (
        space: CGFloat(11.0),
        channel: CGFloat(35.0),
        player: CGFloat(50.0),
        volumeCircle: CGFloat(50),
        volumeSlider: CGFloat(50),
        assosiativeButtonsNormal: CGFloat(0.9),
        assosiativeButtonsExpand: CGFloat(2.5)
    )

    private let geometryFor38mm: GEOMETRY = (
        space: CGFloat(8.0),
        channel: CGFloat(31.0),
        player: CGFloat(44.0),
        volumeCircle: CGFloat(44),
        volumeSlider: CGFloat(44),
        assosiativeButtonsNormal: CGFloat(0.9),
        assosiativeButtonsExpand: CGFloat(2.5)
    )

    private let geometryFor44mm: GEOMETRY = (
        space: CGFloat(11.0),
        channel: CGFloat(35.0),
        player: CGFloat(50.0),
        volumeCircle: CGFloat(50),
        volumeSlider: CGFloat(50),
        assosiativeButtonsNormal: CGFloat(0.9),
        assosiativeButtonsExpand: CGFloat(2.5)
    )

    private let geometryFor40mm: GEOMETRY = (
        space: CGFloat(11.0),
        channel: CGFloat(35.0),
        player: CGFloat(50.0),
        volumeCircle: CGFloat(50),
        volumeSlider: CGFloat(50),
        assosiativeButtonsNormal: CGFloat(0.9),
        assosiativeButtonsExpand: CGFloat(2.5)
    )

    //-----------------------------------------------------------------------------------------
    // MARK: - initialization
    //-----------------------------------------------------------------------------------------
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        crownSequencer.delegate = self
        let wsize = watchSize()
        geometry = wsize == .s38mm ? geometryFor38mm :
                   wsize == .s42mm ? geometryFor42mm :
                   wsize == .s40mm ? geometryFor40mm :
                                     geometryFor44mm

        pageData = self.context?.page as? AVAccessory

        //--------------------------------------------------------------------------------------------
        // setup volume units
        //--------------------------------------------------------------------------------------------
        volumeBackgroundCircleObject = InterfaceCircle(withInterfaceImage: volumeBackgroundCircleImage,
                                                       size: geometry.volumeCircle)
        volumeCircleObject = InterfaceCircle(withInterfaceImage: volumeCircleImage,
                                             size: geometry.volumeCircle)
        volumeBackgroundCircleObject.setCircleAngle(1)
        setVolumeColor(withFocus: false)
        volumeData = VolumeData(
            sliderObject: volumeSlider,
            circleObject: volumeCircleObject,
            speakerIcon: volumeSpeakerIcon,
            portal: self.context?.portal,
            page: self.pageData
        )
        
        //--------------------------------------------------------------------------------------------
        // set up button animation
        //--------------------------------------------------------------------------------------------
        let normalRatio = 0.7
        let pushedRatio = 0.4
        playPauseButtonAnimation = ButtonAnimation(
            withSizeChengee: playPauseButtonSizeChangee, normalSizeRatio: normalRatio, pushedSizeRatio: pushedRatio,
            colorChangee: playPauseButtonColorChangee,
            normalColor: appColor.clear, pushedColor: appColor.defaultLightDark)
        forwardButtonAnimation = ButtonAnimation(
            withSizeChengee: forwardButtonSizeChangee, normalSizeRatio: normalRatio, pushedSizeRatio: pushedRatio,
            colorChangee: forwardButtonColorChangee,
            normalColor: appColor.clear, pushedColor: appColor.defaultLightDark)
        rewindButtonAnimation = ButtonAnimation(
            withSizeChengee: rewindButtonSizeChangee, normalSizeRatio: normalRatio, pushedSizeRatio: pushedRatio,
            colorChangee: rewindButtonColorChangee,
            normalColor: appColor.clear, pushedColor: appColor.defaultLightDark)
        let altPushedRatio = 0.8
        altForwardButtonAnimation = ButtonAnimation(
            withSizeChengee: altForwardButtonSizeChangee, normalSizeRatio: 1.0, pushedSizeRatio: altPushedRatio,
            colorChangee: nil, normalColor: nil, pushedColor: nil)
        altRewindButtonAnimation = ButtonAnimation(
            withSizeChengee: altRewindButtonSizeChangee, normalSizeRatio: 1.0, pushedSizeRatio: altPushedRatio,
            colorChangee: nil, normalColor: nil, pushedColor: nil)

        
        //--------------------------------------------------------------------------------------------
        // personalizing
        //--------------------------------------------------------------------------------------------
        if self.context != nil {
            let channels = self.context?.portal.config?.tvchannels
            let items = channels?.map{ channel -> WKPickerItem in
                let item = WKPickerItem()
                item.title = channel.description
                return item
            }
            channelPicker.setItems(items)
            
            channelGroup.setHidden(pageData?.tvChannelName == nil)
            playerGroup.setHidden(pageData?.player == nil)
            assosiativeButtons.setHidden(pageData?.altSkip == nil)
            volumeCircle.setHidden(pageData?.volume == nil)
            volumeGroup.setHidden(pageData?.volume == nil && pageData?.altSkip == nil)
            
            if let altSkip = pageData?.altSkip {
                altForwardButtonLabel.setText(altSkip.forward?.description)
                altRewindButtonLabel.setText(altSkip.backward?.description)
            }
            
            reflectRemoteStatus()
        }else{
            setTitle("AV Page")
            let channels = ConfigurationController.sharedController.registeredPortals.first?.config?.tvchannels
            let items = channels?.map{ channel -> WKPickerItem in
                let item = WKPickerItem()
                item.title = channel.description
                return item
            }
            channelPicker.setItems(items)
            volumeData?.setValue(50)
            altForwardButtonLabel.setText("30")
            altRewindButtonLabel.setText("30")
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - status transition
    //-----------------------------------------------------------------------------------------
    private var lastUpdateCharacteristicsDate = Date(timeIntervalSince1970: 0)
    override func willActivate() {
        super.willActivate()
        
        adjustUI()
        let now = Date()
        if now.timeIntervalSince(lastUpdateCharacteristicsDate) > 60,
            let volume = pageData?.volume, volume.volumeValue == nil,
            let portal = context?.portal {
            lastUpdateCharacteristicsDate = now
            weak var weakSelf = self
            pageData?.updateCharacteristicStatus(portal: portal, notifier: {
                weakSelf?.reflectRemoteStatus()
            })
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func adjustUI() {
        if channelIsExpanded {
            channelPicker.focus()
        }else{
            crownSequencer.focus()
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - reflect remote status
    //-----------------------------------------------------------------------------------------
    private func reflectRemoteStatus() {
        volumeData?.setValue(pageData?.volume?.volumeValue)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Channel control
    //-----------------------------------------------------------------------------------------
    private var channelIsExpanded = false
    private var channelExpansionTimer : Timer?
    private var channelCommitTimer : Timer?
    
    private func toggleChannelExpansion() {
        if channelIsExpanded {
            animate(withDuration: 0.3){
                [unowned self] in
                self.channelGroup.setHeight(self.geometry.channel)
                self.playerGroup.setHeight(self.geometry.player)
            }
            crownSequencer.focus()
        }else{
            resetVolumeSlider()
            animate(withDuration: 0.3){
                [unowned self] in
                self.channelGroup.setHeight(self.geometry.channel + self.geometry.player)
                self.playerGroup.setHeight(0)
            }
            channelPicker.focus()
            volumeColorTimer?.fire()
        }
        channelIsExpanded = !channelIsExpanded
    }
    
    private func resetChannelExpansion() {
        channelExpansionTimer?.fire()
    }

    private func setChannelExpansionTimer(_ interval: TimeInterval) {
        channelExpansionTimer?.invalidate()
        channelExpansionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false){
            [unowned self] _ in
            self.toggleChannelExpansion()
            self.channelExpansionTimer = nil
        }
    }
    
    private var is1stFocus = true
    override func pickerDidFocus(_ picker: WKInterfacePicker) {
        if !channelIsExpanded && !is1stFocus {
            toggleChannelExpansion()
            setChannelExpansionTimer(2)
        }
        is1stFocus = false
    }

    private var pickerItemIndex = 0

    private func setChannelCommitTimer(_ interval: TimeInterval) {
        channelCommitTimer?.invalidate()
        weak var weakSelf = self
        channelCommitTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false){ _ in
            if let portal = weakSelf?.context?.portal, let channels = portal.config?.tvchannels {
                weakSelf?.pageData?.tvChannelName?.setChannel(portal: portal){
                    return channels[weakSelf?.pickerItemIndex ?? 0].name
                }
            }
            self.channelCommitTimer = nil
        }
    }

    @IBAction func channelPickerAction(_ value: Int) {
        pickerItemIndex = value
        if channelIsExpanded {
            setChannelExpansionTimer(2)
            setChannelCommitTimer(0.5)
            /*
            if let portal = context?.portal, let channels = portal.config?.tvchannels {
                weak var weakSelf = self
                pageData?.tvChannelName?.setChannel(portal: portal){
                    return channels[weakSelf?.pickerItemIndex ?? 0].name
                }
            }
             */
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Volume slider control
    //-----------------------------------------------------------------------------------------
    private var sliderIsShrinked = true

    private func toggleVolumeSlider() {
        if sliderIsShrinked {
            resetChannelExpansion()
            self.animate(withDuration: 0.3){
                [unowned self] in
                self.sliderGroup.setAlpha(1.0)
                self.sliderGroup.setRelativeWidth(1.0, withAdjustment: 0.0)
                self.assosiativeButtons.setAlpha(0)
                self.volumeCircle.setAlpha(0)
                self.volumeTapGesture.isEnabled = false
            }
        }else{
            self.animate(withDuration: 0.3){
                [unowned self] in
                self.sliderGroup.setAlpha(0.0)
                self.sliderGroup.setWidth(self.geometry.volumeSlider)
                self.assosiativeButtons.setAlpha(1)
                self.volumeCircle.setAlpha(1.0)
                self.volumeTapGesture.isEnabled = true
            }
        }
        sliderIsShrinked = !sliderIsShrinked
    }
    
    private func resetVolumeSlider() {
        volumeShrinkTimer?.fire()
    }

    private var volumeShrinkTimer: Timer?
    
    private func setVolumeShrinkTimer(_ interval: TimeInterval) {
        volumeShrinkTimer?.invalidate()
        volumeShrinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false){
            [unowned self] _ in
            if !self.sliderIsShrinked {
                self.toggleVolumeSlider()
            }
            self.volumeShrinkTimer = nil
        }
    }
    
    private func resetVolumeShrinkTimer() {
        volumeShrinkTimer?.invalidate()
        volumeShrinkTimer = nil
    }
    
    private func setVolumeColor(withFocus focus: Bool) {
        if focus {
            volumeBackgroundCircleImage.setTintColor(appColor.focusDark)
            volumeCircleImage.setTintColor(appColor.focus)
            volumeSpeakerIcon.setTintColor(appColor.focus)
        }else{
            volumeBackgroundCircleImage.setTintColor(appColor.themeDark)
            volumeCircleImage.setTintColor(appColor.theme)
            volumeSpeakerIcon.setTintColor(appColor.defaultUnit)
        }
    }
    
    @IBAction func handleGesture(_ gesture: WKTapGestureRecognizer) {
        if sliderIsShrinked {
            toggleVolumeSlider()
            setVolumeShrinkTimer(2)
        }
    }
    
    @IBAction func volumeSliderAction(_ value: Float) {
        if !sliderIsShrinked {
            volumeData?.setValue(Int(value))
            setVolumeShrinkTimer(2)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Delegate methods for crown
    //-----------------------------------------------------------------------------------------
    private var isInVolumeRotation = false
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        if !channelIsExpanded {
            volumeData?.addValueDelta(rotationalDelta * 30)
            if !isInVolumeRotation {
                animate(withDuration: 0.3){
                    [unowned self] in
                    self.setVolumeColor(withFocus: true)
                }
            }
            setVolumeShrinkTimer(2)
        }
        isInVolumeRotation = true
        volumeColorTimer?.invalidate()
        volumeColorTimer = nil
    }

    private var volumeColorTimer : Timer?
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?){
        volumeColorTimer?.invalidate()
        volumeColorTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){
            [unowned self] _ in
            self.animate(withDuration: 0.3){
                [unowned self] in
                self.setVolumeColor(withFocus: false)
            }
            self.volumeColorTimer = nil
        }
        isInVolumeRotation = false
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - actions for each button
    //-----------------------------------------------------------------------------------------
    @IBAction func playPauseButtonAction() {
        initiateButtonAnimation(playPauseButtonAnimation)
        if let portal = context?.portal {
            pageData?.player?.invokeAction(onPortal: portal, withVerb: .playPause)
        }
    }

    @IBAction func forwardButtonAction() {
        initiateButtonAnimation(forwardButtonAnimation)
        if let portal = context?.portal {
            pageData?.player?.invokeAction(onPortal: portal, withVerb: .forward)
        }
    }

    @IBAction func rewindButtonAction() {
        initiateButtonAnimation(rewindButtonAnimation)
        if let portal = context?.portal {
            pageData?.player?.invokeAction(onPortal: portal, withVerb: .rewind)
        }
    }

    @IBAction func altForwardButtonAction() {
        initiateButtonAnimation(altForwardButtonAnimation)
        if let portal = context?.portal {
            pageData?.altSkip?.invokeAction(onPortal: portal, withVerb: .forward)
        }
    }

    @IBAction func altRewindButtonAction() {
        initiateButtonAnimation(altRewindButtonAnimation)
        if let portal = context?.portal {
            pageData?.altSkip?.invokeAction(onPortal: portal, withVerb: .rewind)
        }
    }
    
    private func initiateButtonAnimation(_ animation: ButtonAnimation?){
        animation?.setState(false)
        DispatchQueue.main.async {
            [unowned self] in
            self.animate(withDuration: 0.3){
                animation?.setState(true)
            }
        }
    }
    
    @IBAction func togglePowerMenuAction() {
        if let portal = context?.portal {
            pageData?.togglePowerStatus(viaPortal: portal)
        }
    }
}


//-----------------------------------------------------------------------------------------
// MARK: - Volume representation
//-----------------------------------------------------------------------------------------
private class VolumeData {
    private var rawValue : Double?
    private var syncedValue : Int?
    private var isRelativeMode = true
    
    private weak var sliderObject: WKInterfaceSlider?
    private weak var circleObject: InterfaceCircle?
    private weak var speakerIcon: WKInterfaceImage?
    
    private let portal: Portal?
    private let page: AVAccessory?
    
    var valueMax = 100.0
    var valueMin = 0.0
    
    init(sliderObject: WKInterfaceSlider, circleObject: InterfaceCircle, speakerIcon: WKInterfaceImage,
         portal: Portal?, page: AVAccessory?){
        self.sliderObject = sliderObject
        self.circleObject = circleObject
        self.speakerIcon = speakerIcon
        self.portal = portal
        self.page = page
    }
    
    var value : Int? {
        if let value = rawValue {
            return Int(value)
        }else{
            return nil
        }
    }

    func setValue(_ value: Int?) {
        if let value = value {
            rawValue = min(max(Double(value), valueMin), valueMax)
            isRelativeMode = false
        }else{
            rawValue = nil
            isRelativeMode = true
        }
        reflectValue()
    }
    
    func addValueDelta(_ delta: Double) {
        if var value = rawValue {
            value += delta
            if !isRelativeMode {
                value = min(max(value, valueMin), valueMax)
            }
            rawValue = value
        } else {
            rawValue = delta
        }
        reflectValue()
    }
    
    private func reflectValue() {
        if let newValue = value {
            if newValue != syncedValue {
                if !isRelativeMode{
                    sliderObject?.setValue(Float(newValue))
                    circleObject?.setCircleAngle(Double(newValue) / valueMax)
                    if newValue == Int(valueMin) {
                        speakerIcon?.setImageNamed("volume_speaker_off")
                    }else if syncedValue == Int(valueMin) || syncedValue == nil {
                        speakerIcon?.setImageNamed("volume_speaker_on")
                    }
                    if let portal = portal {
                        weak var weakSelf = self
                        page?.volume?.setVolume(portal: portal){
                            return weakSelf?.value ?? 0
                        }
                    }
                }else{
                    /*
                    if let syncedValue = syncedValue {
                        
                    }
                    */
                }
            }
        }else{
            if syncedValue == nil {
                sliderObject?.setValue(0)
                circleObject?.setCircleAngle(0)
                speakerIcon?.setImageNamed("volume_speaker_on")
            }
        }
        syncedValue = value
    }
}
