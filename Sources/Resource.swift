//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper
import CoreLocation

/// Protocol for resources inside Contentful
public class Resource: ImmutableMappable {

    /// System fields
    public let sys: Sys

    /// The unique identifier of this Resource
    public var id: String {
        return sys.id
    }

    internal init(sys: Sys) {
        self.sys = sys
    }

    // MARK: - <ImmutableMappable>

    public required init(map: Map) throws {
        sys = try map.value("sys")
    }
}

class DeletedResource: Resource {}

// TODO: Document
public class LocalizableResource: Resource, LocalizedResource {

    /// Currently selected locale
    public var currentlySelectedLocale: Locale

    /**
     Content fields. If there is no value for a field associated with the currently selectedLocale,
     the SDK will walk down fallback chain until a value is found. If there is still no value after
     walking the full chain, the field will be omitted from
    */
    public var fields: [FieldName: Any] {
        return Localization.fields(forLocale: currentlySelectedLocale, localizableFields: localizableFields, localizationContext: localizationContext)
    }

    /// TODO: Document that bool returns successful switch of locale.
    @discardableResult public func setLocale(withCode code: LocaleCode) -> Bool {
        guard let newLocale =  localizationContext.locales[code] else {
            return false
        }
        currentlySelectedLocale = newLocale
        return true
    }

    // Locale to Field mapping.
    internal var localizableFields: [FieldName: [LocaleCode: Any]]

    // Context used for handling locales during decoding of `Asset` and `Entry` instances.
    internal let localizationContext: LocalizationContext


    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {

        // Optional propery, not returned when hitting `/sync`.
        var localeCodeSelectedAtAPILevel: LocaleCode?
        localeCodeSelectedAtAPILevel <- map["sys.locale"]

        guard let localizationContext = map.context as? LocalizationContext else {
            // Should never get here; but just in case, let's inform the user what the deal is.
            throw SDKError.localeHandlingError(message: "SDK failed to find the necessary LocalizationContext"
            + "necessary to properly map API responses to internal format.")
        }

        self.localizationContext = localizationContext

        // Get currently selected locale.
        if let localeCode = localeCodeSelectedAtAPILevel, let locale = localizationContext.locales[localeCode] {
            self.currentlySelectedLocale = locale
        } else {
            self.currentlySelectedLocale = localizationContext.default
        }

        self.localizableFields = try Localization.normalizeLocalizedFieldsToDictionary(map: map, selectedLocale: currentlySelectedLocale)

        try super.init(map: map)
    }
}

protocol LocalizedResource {

    var fields: [FieldName: Any] { get }

    var currentlySelectedLocale: Locale { get set }

    var localizableFields: [FieldName: [LocaleCode: Any]] { get }

    var localizationContext: LocalizationContext { get }
}

extension LocalizedResource {

    func string(at key: String) -> String? {
        return fields[key] as? String
    }

    func strings(at key: String) -> [String]? {
        return fields[key] as? [String]
    }

    func int(at key: String) -> Int? {
        return fields[key] as? Int
    }
}

func +=<K: Hashable, V> (left: [K: V], right: [K: V]) -> [K: V] {
    var result = left
    right.forEach { (key, value) in result[key] = value }
    return result
}

func +<K: Hashable, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left += right
}

public extension Dictionary where Key: ExpressibleByStringLiteral {

    func string(at key: Key) -> String? {
        return self[key] as? String
    }

    func strings(at key: Key) -> [String]? {
        return self[key] as? [String]
    }

    func int(at key: Key) -> Int? {
        return self[key] as? Int
    }
}
