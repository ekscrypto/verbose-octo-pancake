//
//  HomeViewModel.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

import Foundation

class HomeViewModel {
    
    struct Dependencies {
        let yelpQueryAllocator: (_ location: String, _ offset: Int, _ completion: YelpQuery.Completion?) -> YelpQueryCompatible
        
        static let defaultDependencies = HomeViewModel.Dependencies(
            yelpQueryAllocator: { location, offset, escapingCompletion in
                guard let completion = escapingCompletion else {
                    fatalError("Invalid configuration")
                }
                return YelpQuery(location: location, offset: offset, completion: completion)
            }
        )
    }
    private let dep: Dependencies
    
    var searchLocation: String = "" {
        didSet { self.resetResultsAndDispatchQueryIfNeeded() }
    }
    
    var businesses: [YelpBusiness] = []
    
    func loadMore() {
        dispatchYelpQuery(searchLocation, offset: businesses.count)
    }
    
    init(with dependencies: Dependencies = .defaultDependencies) {
        self.dep = dependencies
    }
    
    private var pendingQuery: YelpQueryCompatible?
    
    private func resetResultsAndDispatchQueryIfNeeded() {
        businesses.removeAll()
        pendingQuery = nil
        dispatchYelpQuery(searchLocation, offset: 0)
    }
    
    private func dispatchYelpQuery(_ location: String, offset: Int) {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty else {
            return
        }
        
        pendingQuery = dep.yelpQueryAllocator(trimmedLocation, offset) { [weak self] searchResultsOrError in
            self?.processYelpResult(searchResultsOrError)
        }
    }
    
    private func processYelpResult(_ searchResultsOrError: YelpQuery.SearchResult) {
        pendingQuery = nil
        switch searchResultsOrError {
        case .failure(let error):
            _ = error // We ignore the error here, typically we would send some anonymized analytics
        case .success(let searchResults):
            businesses.append(contentsOf: searchResults.businesses)
        }
    }
}
