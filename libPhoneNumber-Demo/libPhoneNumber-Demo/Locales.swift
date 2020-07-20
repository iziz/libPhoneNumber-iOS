//
//  Locales.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/20/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import Foundation
import libPhoneNumberShortNumber

struct LocaleInfo {
    let localeCode: String
    let language: String
}

// These are all of the languages supported by libPhoneNumber.
let locales: [LocaleInfo] = [
    LocaleInfo(localeCode: "Default Device Language", language: "Default Device Language"),
    LocaleInfo(localeCode: "ar", language: "Arabic"),
    LocaleInfo(localeCode: "be", language: "Belarusian"),
    LocaleInfo(localeCode: "bg", language: "Bulgarian"),
    LocaleInfo(localeCode: "bs", language: "Bosnian"),
    LocaleInfo(localeCode: "de", language: "German"),
    LocaleInfo(localeCode: "el", language: "Greek"),
    LocaleInfo(localeCode: "en", language: "English"),
    LocaleInfo(localeCode: "es", language: "Spanish"),
    LocaleInfo(localeCode: "fa", language: "Persian"),
    LocaleInfo(localeCode: "fi", language: "Finnish"),
    LocaleInfo(localeCode: "fr", language: "French"),
    LocaleInfo(localeCode: "hr", language: "Croatian"),
    LocaleInfo(localeCode: "hu", language: "Hungarian"),
    LocaleInfo(localeCode: "hy", language: "Armenian"),
    LocaleInfo(localeCode: "id", language: "Indonesian"),
    LocaleInfo(localeCode: "it", language: "Italian"),
    LocaleInfo(localeCode: "iw", language: "Hebrew"),
    LocaleInfo(localeCode: "ja", language: "Japanese"),
    LocaleInfo(localeCode: "ko", language: "Korean"),
    LocaleInfo(localeCode: "nl", language: "Dutch"),
    LocaleInfo(localeCode: "pl", language: "Polish"),
    LocaleInfo(localeCode: "pt", language: "Portuguese"),
    LocaleInfo(localeCode: "ro", language: "Romanian"),
    LocaleInfo(localeCode: "ru", language: "Russian"),
    LocaleInfo(localeCode: "sq", language: "Albanian"),
    LocaleInfo(localeCode: "sr", language: "Serbian"),
    LocaleInfo(localeCode: "sv", language: "Swedish"),
    LocaleInfo(localeCode: "th", language: "Thai"),
    LocaleInfo(localeCode: "tr", language: "Turkish"),
    LocaleInfo(localeCode: "uk", language: "Ukrainian"),
    LocaleInfo(localeCode: "vi", language: "Vietnamese"),
    LocaleInfo(localeCode: "zh", language: "Chinese"),
    LocaleInfo(localeCode: "zh_Hant", language: "Chinese (Traditional)")
]

// These are all of the formatting options supported by libPhoneNumber.
let formatOptions = ["Select a phone number format", "E164", "INTERNATIONAL", "NATIONAL", "RFC3966"]
