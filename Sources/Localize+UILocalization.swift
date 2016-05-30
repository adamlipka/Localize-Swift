//
//  Localize+UILocalization.swift
//  xOptions
//
//  Created by Adam Lipka on 12.05.2016.
//  Copyright © 2016 Adam Lipka. All rights reserved.
//

import UIKit

let localizePrefix = "key_"

extension NSObject {
    struct AssociatedKeys {
        static var OriginalKey = "OriginalKey"
        static var LanguageSubscription = "LanguageSubscription"
    }
    
    private class Box
    {
        let unbox: Any
        init(_ value: Any) { self.unbox = value }
    }
    
    var originalKey: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.OriginalKey) as? String
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.OriginalKey,
                    newValue as NSString?,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
    
    var languageSubscription: Disposable?{
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.LanguageSubscription) as? Box)?.unbox as? Disposable
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.LanguageSubscription,
                    Box(newValue) as AnyObject?,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
}

extension UILabel {
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        if let text = self.text {
            self.text = text
        }

    }

    override public class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = Selector("setText:")
            let swizzledSelector = #selector(UILabel.swizzled_setText(_:))
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }

    func swizzled_setText(text: String) {
        self.swizzled_setText(text.localized())
        superview?.layoutIfNeeded()
        if text.containsString(localizePrefix) {
            self.originalKey = text
            print(text)
            if languageSubscription == nil {
                languageSubscription = Localize.languageChangeSubject
                    .subscribeNext {[weak self] _ in
                        if let strongSelf = self, let originalKey = self?.originalKey {
                            strongSelf.text = originalKey
                        }
                }
            }
            
        }
    }
}


extension UIButton {
}

extension UIBarButtonItem {
}

extension UIBarItem {
}

extension UINavigationItem {
}

extension UISearchBar {
}

extension UISegmentedControl {
    
}

extension UITextField {
    
}

extension UITextView {
    
}

extension UIViewController {

}