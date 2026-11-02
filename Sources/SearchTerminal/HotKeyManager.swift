import Foundation
import Carbon
import Cocoa

public class HotKeyManager {
    public static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeySignature: OSType = 0x5354524D // 'STRM'
    private let hotKeyIDNumber: UInt32 = 1
    
    public var onHotKeyPressed: (() -> Void)?
    
    private init() {
        installCarbonHandler()
    }
    
    private func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(theEvent,
                                            EventParamName(kEventParamDirectObject),
                                            EventParamType(typeEventHotKeyID),
                                            nil,
                                            MemoryLayout<EventHotKeyID>.size,
                                            nil,
                                            &hotKeyID)
                
                if err == noErr && hotKeyID.signature == manager.hotKeySignature {
                    DispatchQueue.main.async {
                        manager.onHotKeyPressed?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        
        if status != noErr {
            print("Failed to install Carbon event handler: \(status)")
        }
    }
    
    public func register(preset: HotKeyPreset) {
        unregister()
        
        var keyCode: UInt32 = UInt32(kVK_Space)
        var modifiers: UInt32 = UInt32(optionKey)
        
        switch preset {
        case .optionSpace:
            keyCode = UInt32(kVK_Space)
            modifiers = UInt32(optionKey)
        case .cmdShiftSpace:
            keyCode = UInt32(kVK_Space)
            modifiers = UInt32(cmdKey | shiftKey)
        case .optionP:
            keyCode = UInt32(kVK_ANSI_P)
            modifiers = UInt32(optionKey)
        case .cmdShiftF:
            keyCode = UInt32(kVK_ANSI_F)
            modifiers = UInt32(cmdKey | shiftKey)
        }
        
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyIDNumber)
        let status = RegisterEventHotKey(keyCode,
                                         modifiers,
                                         hotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey \(preset.rawValue): \(status)")
        } else {
            print("Successfully registered hotkey: \(preset.rawValue)")
        }
    }
    
    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    deinit {
        unregister()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
}

