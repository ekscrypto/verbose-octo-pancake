//
//  YelpQuery.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//
//  Expected YelpQuery behaviors
//  *) URLSession dataTask created & resumed immediately upon instantiation
//  *) URLSession dataTask cancelled immediately if YelpQuery is released from memory before HTTP response is received, completion handler NOT called
//  *) On successful HTTP response, JSON can be decoded properly
//  *) On unauthorized or other non-successful HTTP response we receive YelpQuery.Errors.unexpectedHttpResponse error with URLResponse object
//  *) On communication failure (airplane mode, etc), we receive YelpQuery.Errors.unexpectedHttpResponse with no URLResponse but with a defined Error object
//  *) Regardless if successful or failed, the YelpQuery completion closure is called if the YelpQuery object is still in memory

import Foundation

protocol YelpQueryCompatible: AnyObject {}

class YelpQuery: YelpQueryCompatible {
    
    static let timeout: TimeInterval = 10

    typealias SearchResult = Result<YelpSearchResults, Error>
    typealias Completion = (SearchResult) -> Void
    
    struct Dependencies {
        let urlSession: URLSessionDataTaskCompatible
        
        static let iOSDefaultDependencies = Dependencies(urlSession: URLSession.shared)
    }
    
    enum Errors: Error {
        case unexpectedHttpResponse(URLResponse?, Error?)
    }
    
    var inProgress: Bool = true
    var result: SearchResult?
    
    private let dep: Dependencies
    private let urlRequest: URLRequest
    private let completion: (SearchResult) -> Void
    private var activeDataTask: URLSessionDataTaskCancellable?
    
    init(with dependencies: Dependencies = .iOSDefaultDependencies, location: String, offset: Int = 0, completion: @escaping Completion) {
        self.dep = dependencies
        self.urlRequest = Self.urlRequest(location: location, offset: offset)
        self.completion = completion
        self.dispatchQuery()
    }
    
    deinit {
        activeDataTask?.cancel()
    }
    
    /// Generate a URLRequest object for a Yelp Business Search query using the location and offset specified
    /// - Parameters:
    ///   - location: String for the location to search
    ///   - offset: Offset within the search result from which business listings should be returned
    /// - Returns: Fully formed URLRequest object
    private static func urlRequest(location: String, offset: Int) -> URLRequest {
        guard var components = URLComponents(string: "https://api.yelp.com/v3/businesses/search") else {
            fatalError("Please verify the search query URL, it seems to be invalid")
        }

        components.queryItems = [
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
            ]
        
        guard let url = components.url else {
            fatalError("We expect the URL object to always be defined since the URLComponents was created using a URL, see above.")
        }
        var yelpRequest = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: Self.timeout)
        yelpRequest.addValue("Bearer \(Secrets.yelpApiKey)", forHTTPHeaderField: "Authorization")
        return yelpRequest
    }
    
    private func extractResults(_ dataOrNil: Data?, _ urlResponseOrNil: URLResponse?, _ errorOrNil: Error?) -> SearchResult {
        SearchResult(catching: {
            guard let httpResponse = urlResponseOrNil as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = dataOrNil
            else {
                throw Errors.unexpectedHttpResponse(urlResponseOrNil, errorOrNil)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            return try decoder.decode(YelpSearchResults.self, from: data)
        })
    }
    
    private func dispatchQuery() {
        let task = dep.urlSession.dataTask(with: self.urlRequest) { [weak self] dataOrNil, urlResponseOrNil, errorOrNil in
            assert(!Thread.isMainThread)
            self?.processQuery(dataOrNil, urlResponseOrNil, errorOrNil)
        }
        activeDataTask = task
        task.resume()
    }
    
    private func processQuery(_ dataOrNil: Data?, _ urlResponseOrNil: URLResponse?, _ errorOrNil: Error?) {
        let searchResult = extractResults(dataOrNil, urlResponseOrNil, errorOrNil)
        DispatchQueue.main.async { [weak self] in self?.completion(searchResult) }
    }
}
