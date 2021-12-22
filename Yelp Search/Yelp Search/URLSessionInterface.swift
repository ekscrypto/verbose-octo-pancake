//
//  URLSessionInterface.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

import Foundation

protocol URLSessionDataTaskCancellable: AnyObject {
    func resume()
    func cancel()
}
extension URLSessionDataTask: URLSessionDataTaskCancellable {}

protocol URLSessionDataTaskCompatible {
    func dataTask(with request: URLRequest, onCompletion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskCancellable
}
extension URLSession: URLSessionDataTaskCompatible {
    func dataTask(with request: URLRequest, onCompletion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskCancellable {
        self.dataTask(with: request, completionHandler: onCompletion)
    }
}
