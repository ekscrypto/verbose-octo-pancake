//
//  YelpBusinessGenerator.swift
//  Yelp SearchTests
//
//  Created by Dave Poirier on 2021-12-21.
//

//  Note: To reduce the time involved and external dependencies most strings are UUID().uuidString. However
//  in a production system the data generators would be generating closer-to-reality values, possibly leveraging
//  third-party libraries like Fakery (https://github.com/vadymmarkov/Fakery)

import Foundation

class YelpBusinessGenerator {
    static func generate(count: Int) -> [YelpBusiness] {
        var businesses: [YelpBusiness] = []
        for _ in 0..<count {
            businesses.append(generateOne())
        }
        return businesses
    }
    
    static func generateOne() -> YelpBusiness {
        YelpBusiness(
            imageUrl: URL(string: "https://\(UUID()).test/\(UUID()).png")!,
            name: UUID().uuidString,
            rating: [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0].randomElement()!,
            location: YelpBusinessLocation(
                city: UUID().uuidString,
                country: UUID().uuidString,
                address1: UUID().uuidString,
                address2: UUID().uuidString,
                address3: UUID().uuidString,
                state: UUID().uuidString,
                zipCode: UUID().uuidString),
            phone: UUID().uuidString,
            reviewCount: Int.random(in: 0...999),
            url: URL(string: "https://\(UUID()).test/\(UUID())")!)
    }
}
