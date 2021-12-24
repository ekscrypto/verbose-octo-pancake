//
//  YelpQueryTests.swift
//  Yelp SearchTests
//
//  Created by Dave Poirier on 2021-12-21.
//

import XCTest

final class YelpQueryTests: XCTestCase {
    
    private let defaultTimeout: TimeInterval = 2.0
    private var mockUrlSession: MockUrlSession!
    private var testDependencies: YelpQuery.Dependencies!
    
    override func setUpWithError() throws {
        mockUrlSession = MockUrlSession()
        testDependencies = YelpQuery.Dependencies(urlSession: mockUrlSession)
    }
    
    override func tearDownWithError() throws {
        ensureClosuresDontRetainSelf()
        mockUrlSession = nil
        testDependencies = nil
    }
    
    private func ensureClosuresDontRetainSelf() {
        mockUrlSession.onDataTask = MockUrlSession.defaultOnDataTaskHandler
    }
    
    struct BaseExpectations {
        let dataTaskDispatched = XCTestExpectation(description: "Upon instantiating the query a dataTask should immediately be dispatched on the provided URLSession")
        let queryCompletionCalled = XCTestExpectation(description: "Upon receiving a successful response, the YelpQuery should call its completion handler")
    }

    func testQuery_successfulResponse_expectsSearchResults() {
        let expectations = BaseExpectations()
        
        mockUrlSession.onDataTask = { request, _ in
            expectations.dataTaskDispatched.fulfill()
            return MockUrlSession.yelpSuccessResponse(request: request)
        }

        let query = YelpQuery(with: testDependencies,
                              location: "San Francisco",
                              offset: 0) { searchResultsOrError in
            expectations.queryCompletionCalled.fulfill()
            guard case .success(let searchResults) = searchResultsOrError else {
                XCTFail("Expected a successful HTTP response to provide a YelpSearchResults")
                return
            }
            XCTAssertEqual(searchResults.total, 8228)
            XCTAssertEqual(searchResults.businesses.count, 1)
            XCTAssertEqual(searchResults.businesses.first?.name, "Four Barrel Coffee")
            XCTAssertEqual(searchResults.businesses.first?.imageUrl, "http://s3-media2.fl.yelpcdn.com/bphoto/MmgtASP3l_t4tPCL1iAsCg/o.jpg")
            XCTAssertTrue(Thread.isMainThread)
        }
        wait(for: [expectations.dataTaskDispatched, expectations.queryCompletionCalled], timeout: defaultTimeout, enforceOrder: true)
        _ = query
    }
    
    func testQuery_noHttpResponse_epectsError() {
        enum TestError: Error {
            case testError
        }
        let expectations = BaseExpectations()
        mockUrlSession.onDataTask = { _, _ in
            expectations.dataTaskDispatched.fulfill()
            return .networkError(TestError.testError)
        }
        let query = YelpQuery(with: testDependencies,
                              location: "San Francisco",
                              offset: 0) { searchResultsOrError in
            expectations.queryCompletionCalled.fulfill()
            
            guard case .failure(let failureError) = searchResultsOrError else {
                XCTFail("Expected a network failure to result in a failed query")
                return
            }
            
            guard case .unexpectedHttpResponse(let urlResponseOrNil, let errorOrNil) = failureError as? YelpQuery.Errors else {
                XCTFail("When a network failure occurs, YelpQuery is expected to return both the URLResponse and Error objects wrapped in YelpQuery.Errors.unexpectedHttpResponse object")
                return
            }
            
            XCTAssertNil(urlResponseOrNil, "No URLResponse should be provided when communication to server failed")
            XCTAssertEqual(errorOrNil as? TestError, .testError, "The error reported by URLSession should be included as is")
        }
        wait(for: [expectations.dataTaskDispatched, expectations.queryCompletionCalled], timeout: defaultTimeout, enforceOrder: true)
        _ = query
    }
    
    func testQuery_unauthorizedHttpResponse_expectsError() {
        let expectations = BaseExpectations()
        mockUrlSession.onDataTask = { urlRequest, _ in
            expectations.dataTaskDispatched.fulfill()
            return MockUrlSession.unauthorizedResponse(request: urlRequest)
        }
        let query = YelpQuery(with: testDependencies,
                              location: "San Francisco",
                              offset: 0) { searchResultsOrError in
            expectations.queryCompletionCalled.fulfill()
            
            guard case .failure(let failureError) = searchResultsOrError else {
                XCTFail("Expected a network failure to result in a failed query")
                return
            }
            
            guard case .unexpectedHttpResponse(let urlResponseOrNil, let errorOrNil) = failureError as? YelpQuery.Errors else {
                XCTFail("When a network failure occurs, YelpQuery is expected to return both the URLResponse and Error objects wrapped in YelpQuery.Errors.unexpectedHttpResponse object")
                return
            }
            
            XCTAssertNotNil(urlResponseOrNil, "The URLResponse object should be provided when a response is received from the HTTP server")
            XCTAssertEqual((urlResponseOrNil as? HTTPURLResponse)?.statusCode, 401, "Unauthorized response of MockUrlSession set HTTP status code 401 and this code should be returned as is")
            XCTAssertNil(errorOrNil, "This value should match the Error? object of the URLSession dataTask completion closure parameter, in this case should be nil")
        }
        wait(for: [expectations.dataTaskDispatched, expectations.queryCompletionCalled], timeout: defaultTimeout, enforceOrder: true)
        _ = query
    }
    
    func testQuery_releasedBeforeResponse_expectsDataTaskCancelled() {
        var cancellableDataTask: MockUrlSession.Cancellable?
        let expectations = BaseExpectations()
        
        mockUrlSession.onDataTask = { _, dataTask in
            cancellableDataTask = dataTask
            expectations.dataTaskDispatched.fulfill()
            return .doNothing
        }
        var query: YelpQuery? = YelpQuery(with: testDependencies,
                                          location: "San Francisco",
                                          offset: 0) { _ in
            XCTFail("The network request should never have completed in this test, therefore the YelpQuery should never have called its completion closure")
        }
        wait(for: [expectations.dataTaskDispatched], timeout: defaultTimeout)
        
        _ = query // <- required to avoid Xcode warning for variable written-to but never read
        query = nil // <- will cause query to be released from memory, which should trigger deinit()

        XCTAssertNotNil(cancellableDataTask, "URLSession dataTask should have been called and custom handler just above should have recorded the associated task")
        XCTAssertTrue(cancellableDataTask?.cancelCalled ?? false, "When the YelpQuery is released from memory, it's dataTask should be cancelled")
    }

    private final class MockUrlSession: URLSessionDataTaskCompatible {
        
        enum DesiredOutcome {
            case networkError(Error)
            case httpResponse(HTTPURLResponse, Data?)
            case doNothing
        }
        
        enum Errors: Error {
            case undefined
        }
        
        final class Cancellable: URLSessionDataTaskCancellable {
            var resumeCalled = false
            var cancelCalled = false
            var onResume: () -> Void = { /* will be set by MockURLSession dataTask function */ }
            
            func resume() {
                XCTAssertFalse(resumeCalled)
                XCTAssertFalse(cancelCalled)
                resumeCalled = true
                onResume()
            }

            func cancel() {
                XCTAssertTrue(resumeCalled)
                XCTAssertFalse(cancelCalled)
                cancelCalled = true
            }
        }
        
        typealias OnDataTaskHandler = (URLRequest, Cancellable) -> DesiredOutcome
        static let defaultOnDataTaskHandler: OnDataTaskHandler = { _, _ in .networkError(Errors.undefined) }
        
        var onDataTask: (URLRequest, Cancellable) -> DesiredOutcome = MockUrlSession.defaultOnDataTaskHandler

        private let networkQueue = DispatchQueue(label: "YelpQueryTests.MockUrlSession")

        func dataTask(with request: URLRequest, onCompletion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskCancellable {
            let task = Cancellable()
            let outcome = onDataTask(request, task)
            task.onResume = { [weak self] in
                self?.networkQueue.async {
                    switch outcome {
                    case .networkError(let error):
                        onCompletion(nil, nil, error)
                    case .httpResponse(let httpUrlResponse, let optionalData):
                        onCompletion(optionalData, httpUrlResponse, nil)
                    case .doNothing:
                        break
                    }
                }
            }
            return task
        }
        
        static func yelpSuccessResponse(request: URLRequest) -> MockUrlSession.DesiredOutcome {
            // Sample extracted from documentation at https://www.yelp.ca/developers/documentation/v3/business_search
            let contentJson = """
        {
          "total": 8228,
          "businesses": [
            {
              "rating": 4,
              "price": "$",
              "phone": "+14152520800",
              "id": "E8RJkjfdcwgtyoPMjQ_Olg",
              "alias": "four-barrel-coffee-san-francisco",
              "is_closed": false,
              "categories": [
                {
                  "alias": "coffee",
                  "title": "Coffee & Tea"
                }
              ],
              "review_count": 1738,
              "name": "Four Barrel Coffee",
              "url": "https://www.yelp.com/biz/four-barrel-coffee-san-francisco",
              "coordinates": {
                "latitude": 37.7670169511878,
                "longitude": -122.42184275
              },
              "image_url": "http://s3-media2.fl.yelpcdn.com/bphoto/MmgtASP3l_t4tPCL1iAsCg/o.jpg",
              "location": {
                "city": "San Francisco",
                "country": "US",
                "address2": "",
                "address3": "",
                "state": "CA",
                "address1": "375 Valencia St",
                "zip_code": "94103"
              },
              "distance": 1604.23,
              "transactions": ["pickup", "delivery"]
            }
          ],
          "region": {
            "center": {
              "latitude": 37.767413217936834,
              "longitude": -122.42820739746094
            }
          }
        }
        """
            guard let url = request.url else {
                fatalError("The URLRequest object forwarded to URLSession should contain a valid URL")
            }
            let responseContent = contentJson.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: [
                "Content-Type": "application/json; charset=utf-8",
                "Content-Length": String(responseContent.count)
            ])!
            return .httpResponse(httpResponse, responseContent)
        }
        
        static func unauthorizedResponse(request: URLRequest) -> MockUrlSession.DesiredOutcome {
            guard let url = request.url else {
                fatalError("The URLRequest object forwarded to URLSession should contain a valid URL")
            }
            let responseContent = "{\"error\":\"Unauthorized\"}".data(using: .utf8)!
            let httpResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "1.1", headerFields: [
                "Content-Type": "application/json; charset=utf-8",
                "Content-Length": String(responseContent.count)
            ])!
            return .httpResponse(httpResponse, responseContent)
        }

    }
    
}
