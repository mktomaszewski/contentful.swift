//
//  Error.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// Possible errors being thrown by the SDK
public enum SDKError: Error {
    /// Thrown when no valid client is available during sync
    case invalidClient()

    /**
     *  Thrown when receiving an invalid HTTP response
     *
     *  @param URLResponse? Optional URL response that has triggered the error
     */
    case invalidHTTPResponse(response: URLResponse?)

    /**
     *  Thrown when constructing an invalid URL
     *
     *  @param String The invalid URL string
     */
    case invalidURL(string: String)

    /// Thrown if the sync endpoint is called while being in preview mode
    case previewAPIDoesNotSupportSync()

    /**
     *  Thrown when receiving unparseable JSON responses
     *
     *  @param Data The data being parsed
     *  @param String The error which occured during parsing
     */
    case unparseableJSON(data: Data, errorMessage: String)

    /// Thrown when no entry is found matching a specific Entry id
    case noEntryFoundFor(id: String)

    /// Thrown when the construction of a URL pointing to an underlying media file for an Asset is invalid.
    case invalidImageParameters(String)

    /// Thrown when a `Foundation.Data` object is unable to be transformed to a `UIImage` or an `NSImage` object.
    case unableToDecodeImageData
}

/// Errors thrown for queries which have invalid construction.
public enum QueryError: Error {

    var message: String {
        switch self {
        case .invalidSelection(let fieldKeyPath):
            return "Selection for \(fieldKeyPath) is invalid. Make sure it has at most 1 '.' character in it."
        case .maxSelectionLimitExceeded:
            return "Can select at most 99 key paths when using the select operator on a content type."
        case .maximumLimitExceeded:
            return "When limiting the results of a query, results must be limited to a value less than or equal to 1000."
        case .mimetypeSpecifiedOnEntry:
            return "Mimetype group can only be specified when querying Assets. " +
                   "The content_type_id parameter of the query should be nil for mimetype_group to work."
        case .invalidOrderProperty:
            return "Either 'sys' or 'fields' properties must be specified. Prefix your propety name with 'fields.' or 'sys.'."
        case .textSearchTooShort:
            return "Full text search must have a string with more than 1 character."
        }
    }

    /// Thrown if the query string for a full-text search query only has less than 2 characters.
    case textSearchTooShort

    /// Thrown when attempting to order query results with a property that is not prefixed with "fields." or "sys.".
    case invalidOrderProperty

    /// Thrown when a value greater than 1000 is used for limiting the results of a query.
    case maximumLimitExceeded

    /// Thrown when attempting to specify a mimetype_group on model of `Entry` type.
    case mimetypeSpecifiedOnEntry

    /// Thrown when a selection for the `select` operator is constructed in a way that is invalid.
    case invalidSelection(fieldKeyPath: String)

    /// Thrown when over 99 properties have been selected. The CDA only supports 100 selections
    /// and the SDK always includes "sys" as one of them.
    case maxSelectionLimitExceeded
}


/// Information regarding an error received from Contentful
public class ContentfulError: Mappable, Error {

    /// Human readable error message.
    public var message: String?

    /// The identifier of the request, can be useful when making support requests.
    public var requestId: String?

    // Developer note: API Errors are a special case for Object mapping from JSON. 
    // Rather than throw an error which will trigger the Swift error breakpoint in Xcode, 
    // we want to use failable ObjectMapper initializers.

    public var id: String?

    public var type: String?

    // MARK: <Mappable>

    public required init?(map: Map) {
        message     <- map["message"]
        requestId   <- map["requestId"]

        // An error must have these things. 
        guard message != nil && requestId != nil else {
            return nil
        }

        id          <- map["sys.id"]
        type        <- map["sys.type"]
    }

    // Required by ObjectMapper.BaseMappable
    public func mapping(map: Map) {
        message     <- map["message"]
        requestId   <- map["requestId"]
        id          <- map["sys.id"]
        type        <- map["sys.type"]
    }
}
