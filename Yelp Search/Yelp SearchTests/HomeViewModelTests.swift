//
//  HomeViewModelTests.swift
//  Yelp SearchTests
//
//  Created by Dave Poirier on 2021-12-21.
//

import XCTest

final class HomeViewModelTests: XCTestCase {

    private let defaultTimeout: TimeInterval = 2.0
    private var onYelpQueryAllocation: ((MockYelpQuery) -> Void)!
    private var testDependencies: HomeViewModel.Dependencies!
    
    override func setUpWithError() throws {
        testDependencies = HomeViewModel.Dependencies(yelpQueryAllocator: { location, offset, completion in
            let mockYelpQuery = MockYelpQuery(location, offset, completion)
            self.onYelpQueryAllocation(mockYelpQuery)
            return mockYelpQuery
        })
    }

    override func tearDownWithError() throws {
        ensureClosuresDontRetainSelf()
        testDependencies = nil
    }
    
    private func ensureClosuresDontRetainSelf() {
        self.onYelpQueryAllocation = { _ in /* do nothing */ }
    }
    
    func testInit_expectsEmptyLocationAndNoBusinesses() {
        self.onYelpQueryAllocation = { _ in XCTFail("No YelpQuery should be allocated on init") }
        let homeViewModel = HomeViewModel(with: testDependencies)
        XCTAssertEqual(homeViewModel.searchLocation, "", ".searchLocation should be empty by default")
        XCTAssertEqual(homeViewModel.businesses.count, 0, ".businesses should be an empty array by default")
    }
    
    func testSetSearchLocation_whitespacesOnly_NoQueryDispatchedAndNoResults() {
        self.onYelpQueryAllocation = { _ in XCTFail("No YelpQuery should be allocated when the searchLocation contains only whitespaces") }
        let homeViewModel = HomeViewModel(with: testDependencies)
        homeViewModel.searchLocation = " \t \n "
        XCTAssertEqual(homeViewModel.businesses.count, 0, ".businesses should stay empty when searchLocation contains only whitespaces")
    }
    
    private func someRandomString() -> String {
        // For sake of simplicity, return a UUID for now..
        UUID().uuidString
    }
    
    private func prepareAndSendInitialLocations(viewModel: HomeViewModel, expectedLocation: String) -> [YelpBusiness] {
        let queryDispatchedExpectation = XCTestExpectation(description: "When a searchLocation is set, a query for that location should be dispatched")
        let resultsProvidedExpectation = XCTestExpectation(description: "Mock should confirm once the results have been delivered so we can proceed with the behavior validation")

        var allocatedYelpQuery: MockYelpQuery?
        self.onYelpQueryAllocation = { mockYelpQuery in
            allocatedYelpQuery = mockYelpQuery
            queryDispatchedExpectation.fulfill()
            XCTAssertEqual(mockYelpQuery.location, expectedLocation, "Location passed to the YelpQuery should match the location we specified")
            XCTAssertEqual(mockYelpQuery.offset, 0)
        }
        viewModel.searchLocation = expectedLocation
        wait(for: [queryDispatchedExpectation], timeout: defaultTimeout)

        let expectedBusinessesCount = Int.random(in: 1...50)
        let expectedBusinesses = YelpBusinessGenerator.generate(count: expectedBusinessesCount)
        
        allocatedYelpQuery?.send(results: YelpQuery.SearchResult(catching: {
            YelpSearchResults(total: expectedBusinessesCount, businesses: expectedBusinesses)
        }), then: {
            resultsProvidedExpectation.fulfill()
        })
        wait(for: [resultsProvidedExpectation], timeout: defaultTimeout)
        
        return expectedBusinesses
    }
    
    func testSetSearchLocation_someLocationWithResults_expectsQueryForMatchingLocationThenBusinessesListed() {
        let homeViewModel = HomeViewModel(with: testDependencies)
        XCTAssertEqual(homeViewModel.businesses, [])
        let expectedBusinesses = prepareAndSendInitialLocations(viewModel: homeViewModel, expectedLocation: someRandomString())
        XCTAssertEqual(homeViewModel.businesses, expectedBusinesses)        
    }
    
    func testSetSearchLocation_someLocatioThenEmpty_expectsValuesThenEmpty() {
        let homeViewModel = HomeViewModel(with: testDependencies)
        XCTAssertEqual(homeViewModel.businesses, [])
        
        let expectedBusinesses = prepareAndSendInitialLocations(viewModel: homeViewModel, expectedLocation: someRandomString())
        assert(expectedBusinesses.count > 0)
        XCTAssertEqual(homeViewModel.businesses, expectedBusinesses)
        
        homeViewModel.searchLocation = "    "
        XCTAssertEqual(homeViewModel.businesses, [])
    }
    
    private final class MockYelpQuery: YelpQueryCompatible {
        let completion: YelpQuery.Completion
        let location: String
        let offset: Int
        
        init(_ location: String, _ offset: Int, _ escapingCompletion: YelpQuery.Completion?) {
            guard let completion = escapingCompletion else {
                fatalError("Completion should always be provided, it is made optional to make the closure @escaping in protocol")
            }
            self.completion = completion
            self.location = location
            self.offset = offset
        }
        
        func send(results: YelpQuery.SearchResult, then afterCompletion: @escaping () -> Void) {
            DispatchQueue.main.async {
                self.completion(results)
                afterCompletion()
            }
        }
    }
}
