//
//  YelpBusinessLocation.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

import Foundation

struct YelpBusinessLocation: Codable, Equatable {
    let city: String
    let country: String
    let address1: String
    let address2: String
    let address3: String
    let state: String
    let zipCode: String
}
