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
    
    func testLoadMore_emptySearchLocation_noQueryDispatched() {
        let homeViewModel = HomeViewModel(with: testDependencies)
        homeViewModel.searchLocation = " "
        onYelpQueryAllocation = { _ in XCTFail("No query should be dispatched by loadMore when the search location is empty") }
        homeViewModel.loadMore()
    }
    
    func testLoadMore_withInProgressQuery_noAdditionalQueryDispatched() {
        let homeViewModel = HomeViewModel(with: testDependencies)
        let initialQueryDispatchedExpectation = XCTestExpectation(description: "When searchLocation is set with non-empty value a query should immediately be dispatched")
        onYelpQueryAllocation = { _ in
            initialQueryDispatchedExpectation.fulfill()
        }
        homeViewModel.searchLocation = someRandomString()
        wait(for: [initialQueryDispatchedExpectation], timeout: defaultTimeout)
        onYelpQueryAllocation = { _ in XCTFail("When a query is already in progress, loadMore should not trigger another query") }
        homeViewModel.loadMore()
    }
    
    func testLoadMore_initialResultsReceived_additionalQueryWithOffsetDispatched() {
        let homeViewModel = HomeViewModel(with: testDependencies)
        
        // prepare data to use
        let firstSetOfBusinesses = YelpBusinessGenerator.generate(count: 50)
        let secondSetOfBusinesses = YelpBusinessGenerator.generate(count: Int.random(in: 1...50))
        var expectedCombinedSet = firstSetOfBusinesses
        expectedCombinedSet.append(contentsOf: secondSetOfBusinesses)
        let firstApiResult = YelpSearchResults(total: expectedCombinedSet.count, businesses: firstSetOfBusinesses)
        let secondApiResult = YelpSearchResults(total: expectedCombinedSet.count, businesses: secondSetOfBusinesses)

        let firstQueryDispatchedExpectation = XCTestExpectation(description: "After setting the search location the first query should be immediately dispatched")

        onYelpQueryAllocation = { query in
            query.send(results: YelpQuery.SearchResult(catching: { firstApiResult }), then: {
                firstQueryDispatchedExpectation.fulfill()
            })
        }
        homeViewModel.searchLocation = someRandomString()
        wait(for: [firstQueryDispatchedExpectation], timeout: defaultTimeout)
        XCTAssertEqual(homeViewModel.businesses, firstSetOfBusinesses)

        let secondQueryDispatchedExpectation = XCTestExpectation(description: "After calling loadMore when the total received is below the grand total there should be another API call made")
        onYelpQueryAllocation = { query in
            XCTAssertEqual(query.offset, firstSetOfBusinesses.count, "The offset of the loadMore generated query should be equal to the number of results already received")
            query.send(results: YelpQuery.SearchResult(catching: { secondApiResult })) {
                secondQueryDispatchedExpectation.fulfill()
            }
        }
        homeViewModel.loadMore()
        wait(for: [secondQueryDispatchedExpectation], timeout: defaultTimeout)
        XCTAssertEqual(homeViewModel.businesses, expectedCombinedSet)
    }
    
    func testLoadMore_allResultsLoaded_noQueryDispatched() {
        let homeViewModel = HomeViewModel(with: testDependencies)
        _ = prepareAndSendInitialLocations(viewModel: homeViewModel, expectedLocation: someRandomString())
        onYelpQueryAllocation = { _ in XCTFail("When all results have been loaded, loadMore should not trigger a query") }
        homeViewModel.loadMore()
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
