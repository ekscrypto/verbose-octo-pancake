//
//  YelpSearchResults.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

//  Limited-scope data model based on https://www.yelp.ca/developers/documentation/v3/business_search

import Foundation

struct YelpSearchResults: Codable {
    let total: Int
    let businesses: [YelpBusiness]
}
