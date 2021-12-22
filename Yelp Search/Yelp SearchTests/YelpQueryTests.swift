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
    
    override func setUp() {
        mockUrlSession = MockUrlSession()
        testDependencies = YelpQuery.Dependencies(urlSession: mockUrlSession)
    }
    
    override func tearDown() {
        ensureClosuresDontRetainSelf()
        mockUrlSession = nil
        testDependencies = nil
    }
    
    private func ensureClosuresDontRetainSelf() {
        mockUrlSession.onDataTask = MockUrlSession.defaultOnDataTaskHandler
    }

    func testQuery_successfulResponse_expectsSearchResults() {
        let dataTaskDispatchedExpectation = XCTestExpectation(description: "Upon instantiating the query a dataTask should immediately be dispatched on the provided URLSession")
        let queryCompletionCalledExpectation = XCTestExpectation(description: "Upon receiving a successful response, the YelpQuery should call its completion handler")
        
        mockUrlSession.onDataTask = { request in
            dataTaskDispatchedExpectation.fulfill()
            return MockUrlSession.yelpSuccessResponse(request: request)
        }

        let query = YelpQuery(with: testDependencies,
                              location: "San Francisco",
                              offset: 0) { searchResultsOrError in
            queryCompletionCalledExpectation.fulfill()
            guard case .success(let searchResults) = searchResultsOrError else {
                XCTFail("Expected a successful HTTP response to provide a YelpSearchResults")
                return
            }
            XCTAssertEqual(searchResults.total, 8228)
            XCTAssertEqual(searchResults.businesses.count, 1)
            XCTAssertEqual(searchResults.businesses.first?.name, "Four Barrel Coffee")
            XCTAssertTrue(Thread.isMainThread)
        }
        wait(for: [dataTaskDispatchedExpectation, queryCompletionCalledExpectation], timeout: defaultTimeout, enforceOrder: true)
        _ = query
    }

    private final class MockUrlSession: URLSessionDataTaskCompatible {
        
        enum DesiredOutcome {
            case networkError(Error)
            case httpResponse(HTTPURLResponse, Data?)
        }
        
        enum Errors: Error {
            case undefined
        }
        
        final class Cancellable: URLSessionDataTaskCancellable {
            var resumeCalled = false
            var cancelCalled = false
            var onResume: () -> Void
            
            init(onResume: @escaping () -> Void) {
                self.onResume = onResume
            }
            
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
        
        typealias OnDataTaskHandler = (URLRequest) -> DesiredOutcome
        static let defaultOnDataTaskHandler: OnDataTaskHandler = { _ in .networkError(Errors.undefined) }
        
        var onDataTask: (URLRequest) -> DesiredOutcome = MockUrlSession.defaultOnDataTaskHandler

        private let networkQueue = DispatchQueue(label: "YelpQueryTests.MockUrlSession")

        func dataTask(with request: URLRequest, onCompletion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskCancellable {
            let outcome = onDataTask(request)
            let task = Cancellable(onResume: { [weak self] in
                self?.networkQueue.async {
                    switch outcome {
                    case .networkError(let error):
                        onCompletion(nil, nil, error)
                    case .httpResponse(let httpUrlResponse, let optionalData):
                        onCompletion(optionalData, httpUrlResponse, nil)
                    }
                }
            })
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

    }
    
}
