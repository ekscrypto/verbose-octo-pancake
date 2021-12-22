//
//  YelpBusiness.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

//  Limited-scope data model based on https://www.yelp.ca/developers/documentation/v3/business_search

import Foundation

struct YelpBusiness: Codable {
    // Minimum criteria items
    let imageUrl: URL       // URL of photo for this business.
    let name: String        // Name of this business.
    let rating: Decimal     // Rating for this business (value ranges from 1, 1.5, ... 4.5, 5).
    
    // Additional properties for extended project scope (may be removed later!)
    let location: String    // Location of this business, including address, city, state, zip code and country.
    let phone: String       // Phone number of the business.
    let reviewCount: Int    // Number of reviews for this business.
    let url: URL            // URL for business page on Yelp.
}
