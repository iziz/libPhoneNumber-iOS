//
//  NBTextField.swift
//  libPhoneNumber
//
//  Created by tabby on 2015. 11. 7..
//  Copyright © 2015년 ohtalk.me. All rights reserved.
//

import libPhoneNumberiOS


open class NBTextField: UITextField
{
    // MARK: Options/Variables for phone number formatting
    
    let phoneNumberUtility: NBPhoneNumberUtil = NBPhoneNumberUtil()
    var phoneNumberFormatter: NBAsYouTypeFormatter?
    
    var shouldCheckValidationForInputText: Bool = true
    
    var countryCode: String = "US" {//5 NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String {
        didSet {
            phoneNumberFormatter = NBAsYouTypeFormatter(regionCode: countryCode)
            numberTextDidChange()
        }
    }

    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForNotifications()
        phoneNumberFormatter = NBAsYouTypeFormatter(regionCode: countryCode)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: UITextField input managing
    
    override open func deleteBackward() {
        if text?.characters.last == " " {
            if let indexNumberWithWhiteSpace = text?.characters.index((text?.endIndex)!, offsetBy: -1) {
                text = text?.substring(to: indexNumberWithWhiteSpace)
            }
            return
        }
        super.deleteBackward()
    }

    
    // MARK: Notification for "UITextFieldTextDidChangeNotification"
    
    fileprivate func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(NBTextField.numberTextDidChange), name: NSNotification.Name.UITextFieldTextDidChange, object: self)
    }
    
    func numberTextDidChange() {
        let numbersOnly = phoneNumberUtility.normalize(text)
        text = phoneNumberFormatter!.inputStringAndRememberPosition(numbersOnly)
        
        if phoneNumberFormatter!.isSuccessfulFormatting == false && shouldCheckValidationForInputText {
            shakeIt()
        }
    }
    
    func shakeIt() {
        let offset = self.bounds.size.width / 30
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - offset, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + offset, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
}
