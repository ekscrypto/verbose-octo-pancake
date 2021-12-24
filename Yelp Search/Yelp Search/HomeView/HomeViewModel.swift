//
//  HomeViewModel.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

import Foundation

protocol HomeViewModelCompatible: AnyObject {
    var searchLocation: String { get set }
    var businesses: [YelpBusiness] { get }
    var onBusinesses: ([YelpBusiness]) -> Void { get set }
    var onPendingQuery: (Bool) -> Void { get set }
    func loadMore()
}

final class HomeViewModel: HomeViewModelCompatible {
    
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
    
    private(set) var businesses: [YelpBusiness] = [] {
        didSet {
            onBusinesses(businesses)
        }
    }
    var onBusinesses: ([YelpBusiness]) -> Void = { _ in /* by default do nothing */ }
    var onPendingQuery: (Bool) -> Void = { _ in /* by default do nothing */ }
    
    private var totalMatchesOnServer = 0
    
    func loadMore() {
        guard pendingQuery == nil, businesses.count < totalMatchesOnServer else { return }
        dispatchYelpQuery(searchLocation, offset: businesses.count)
    }
    
    init(with dependencies: Dependencies = .defaultDependencies) {
        self.dep = dependencies
    }
    
    private var pendingQuery: YelpQueryCompatible? {
        didSet {
            onPendingQuery(pendingQuery != nil)
        }
    }
    
    private func resetResultsAndDispatchQueryIfNeeded() {
        businesses.removeAll()
        pendingQuery = nil
        totalMatchesOnServer = 0
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
            totalMatchesOnServer = searchResults.total
        }
    }
}
