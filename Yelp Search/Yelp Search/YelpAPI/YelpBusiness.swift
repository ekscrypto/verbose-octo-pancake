//
//  YelpBusiness.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

//  Limited-scope data model based on https://www.yelp.ca/developers/documentation/v3/business_search

import Foundation

struct YelpBusiness: Codable, Equatable, Hashable {
    // Minimum criteria items
    let imageUrl: String    // URL of photo for this business, empty string if undefined
    let name: String        // Name of this business.
    let rating: Float     // Rating for this business (value ranges from 1, 1.5, ... 4.5, 5).
}
