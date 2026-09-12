import SwiftUI
import libPhoneNumberSwiftCore
#if canImport(UIKit)
import UIKit
#endif

/// The result of parsing the field's current text.
///
/// `error` is a concrete ``PhoneNumberValueError`` rather than an existential
/// `Error` so the state can be compared, sent across concurrency domains, and
/// switched over by callers.
public struct PhoneNumberFieldState: Equatable, Sendable {
    public let text: String
    public let e164: String?
    public let regionCode: String?
    public let type: PhoneNumberType
    public let validationResult: ValidationResult?
    public let enrichment: PhoneNumberEnrichment?
    public let isPossible: Bool
    public let isValid: Bool
    public let error: PhoneNumberValueError?

    public init(
        text: String,
        e164: String?,
        regionCode: String?,
        type: PhoneNumberType,
        validationResult: ValidationResult?,
        enrichment: PhoneNumberEnrichment?,
        isPossible: Bool,
        isValid: Bool,
        error: PhoneNumberValueError?
    ) {
        self.text = text
        self.e164 = e164
        self.regionCode = regionCode
        self.type = type
        self.validationResult = validationResult
        self.enrichment = enrichment
        self.isPossible = isPossible
        self.isValid = isValid
        self.error = error
    }
}

public struct PhoneNumberEnrichment: Equatable, Sendable {
    public let carrierName: String?
    public let timeZones: [String]

    public init(carrierName: String?, timeZones: [String]) {
        self.carrierName = carrierName
        self.timeZones = timeZones
    }
}

public protocol PhoneNumberEnriching: Sendable {
    func enrichment(for number: PhoneNumber, regionCode: String?) -> PhoneNumberEnrichment
}

public struct PhoneNumberFieldStyle: Sendable {
    public let validatesWhileEditing: Bool
    public let formatsWhileEditing: Bool
    #if os(iOS) || os(tvOS)
    public let textContentType: UITextContentType?
    #endif

    #if os(iOS) || os(tvOS)
    public init(
        validatesWhileEditing: Bool = true,
        formatsWhileEditing: Bool = true,
        textContentType: UITextContentType? = .telephoneNumber
    ) {
        self.validatesWhileEditing = validatesWhileEditing
        self.formatsWhileEditing = formatsWhileEditing
        self.textContentType = textContentType
    }
    #else
    public init(
        validatesWhileEditing: Bool = true,
        formatsWhileEditing: Bool = true
    ) {
        self.validatesWhileEditing = validatesWhileEditing
        self.formatsWhileEditing = formatsWhileEditing
    }
    #endif

    public static let automatic = PhoneNumberFieldStyle()
}

public struct PhoneNumberFieldFormatter: Sendable {
    private let utility: PhoneNumberUtility
    private let enricher: PhoneNumberEnriching?

    public init(
        utility: PhoneNumberUtility = .shared,
        enricher: PhoneNumberEnriching? = nil
    ) {
        self.utility = utility
        self.enricher = enricher
    }

    public func formattedText(for text: String, defaultRegion: String) -> String {
        let formatter = AsYouTypeFormatter(regionCode: defaultRegion)
        var formatted = ""
        for character in utility.diallableCharactersOnly(text).map(String.init) {
            formatted = formatter.inputDigit(character)
        }
        return formatted.isEmpty ? text : formatted
    }

    public func state(for text: String, defaultRegion: String) -> PhoneNumberFieldState {
        do {
            let number = try utility.parse(text, defaultRegion: defaultRegion)
            let e164 = try? utility.format(number, as: .e164)
            let validationResult = try? utility.possibleNumberReason(number)
            let regionCode = utility.regionCode(for: number)
            return PhoneNumberFieldState(
                text: text,
                e164: e164,
                regionCode: regionCode,
                type: utility.type(of: number),
                validationResult: validationResult,
                enrichment: enricher?.enrichment(for: number, regionCode: regionCode),
                isPossible: utility.isPossibleNumber(number),
                isValid: utility.isValidNumber(number),
                error: nil
            )
        } catch {
            return PhoneNumberFieldState(
                text: text,
                e164: nil,
                regionCode: nil,
                type: .unknown,
                validationResult: nil,
                enrichment: nil,
                isPossible: false,
                isValid: false,
                error: PhoneNumberValueError(error)
            )
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct PhoneNumberTextField<RegionPicker: View>: View {
    private let title: String
    private let defaultRegion: String
    private let style: PhoneNumberFieldStyle
    private let formatter: PhoneNumberFieldFormatter
    private let onStateChange: (PhoneNumberFieldState) -> Void
    private let regionPicker: (String) -> RegionPicker

    @Binding private var text: String

    public init(
        _ title: String = "",
        text: Binding<String>,
        defaultRegion: String,
        style: PhoneNumberFieldStyle = .automatic,
        formatter: PhoneNumberFieldFormatter = PhoneNumberFieldFormatter(),
        onStateChange: @escaping (PhoneNumberFieldState) -> Void = { _ in },
        @ViewBuilder regionPicker: @escaping (String) -> RegionPicker
    ) {
        self.title = title
        self._text = text
        self.defaultRegion = defaultRegion
        self.style = style
        self.formatter = formatter
        self.onStateChange = onStateChange
        self.regionPicker = regionPicker
    }

    public var body: some View {
        HStack {
            regionPicker(defaultRegion)
            TextField(
                title,
                text: Binding(
                    get: { text },
                    set: { updateText($0) }
                )
            )
            #if os(iOS) || os(tvOS)
            .textContentType(style.textContentType)
            #endif
            #if os(iOS) || os(tvOS)
            .keyboardType(.phonePad)
            #endif
        }
        .onAppear {
            notifyState(for: text)
        }
    }

    private func updateText(_ newValue: String) {
        let nextText = style.formatsWhileEditing
            ? formatter.formattedText(for: newValue, defaultRegion: defaultRegion)
            : newValue
        text = nextText
        if style.validatesWhileEditing {
            notifyState(for: nextText)
        }
    }

    private func notifyState(for text: String) {
        onStateChange(formatter.state(for: text, defaultRegion: defaultRegion))
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension PhoneNumberTextField where RegionPicker == EmptyView {
    init(
        _ title: String = "",
        text: Binding<String>,
        defaultRegion: String,
        style: PhoneNumberFieldStyle = .automatic,
        formatter: PhoneNumberFieldFormatter = PhoneNumberFieldFormatter(),
        onStateChange: @escaping (PhoneNumberFieldState) -> Void = { _ in }
    ) {
        self.init(
            title,
            text: text,
            defaultRegion: defaultRegion,
            style: style,
            formatter: formatter,
            onStateChange: onStateChange,
            regionPicker: { _ in EmptyView() }
        )
    }
}
