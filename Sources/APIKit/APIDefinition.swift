//
//  APIDefinition.swift
//  
//
//  Created by kor45cw on 2021/09/30.
//

import Foundation
import OSLog

public typealias HTTPHeaders = [String: String]

public struct ServerHost: RawRepresentable {
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

public enum ContentType: String {
    case json = "application/json"
    case formed = "application/x-www-form-urlencoded"
}

struct EmptyResponse: Decodable {}
struct EmptyParameter: Encodable {}

public protocol APIDefinition {
    associatedtype Response: Decodable
    associatedtype Parameter: Encodable
        
    var serverHost: ServerHost { get }
    var port: String { get }

    var parameters: Parameter? { get set }
    var headers: HTTPHeaders? { get set }
        
    var url: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var contentType: ContentType { get }
    var network: NetworkProtocol { get }
    
    init()
}


public extension APIDefinition {
    init(parameters: Parameter? = nil, headers: HTTPHeaders? = nil) {
        self.init()
        self.parameters = parameters
        self.headers = headers
    }
}


public extension APIDefinition {
    var port: String { "" }
    var contentType: ContentType { .json }
    
    var url: String {
        if path.hasPrefix("/") {
            return "\(serverHost.rawValue)\(path)"
        } else {
            return "\(serverHost.rawValue)/\(path)"
        }
    }
    
    var network: NetworkProtocol {
        Networking.default
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        return .reloadIgnoringCacheData
    }
    
    private var scheme: String {
        "https"
    }
    
    private func urlPrefix(from host: ServerHost) -> String {
        return "\(scheme)://\(host.rawValue)"
    }
    
    func asURLRequest() throws -> URLRequest {
        #if DEBUG
        os_log(.default, log: .data, "🎾==========================================================================🎾")
        os_log(.default, log: .data, "💞Request💞")
        os_log(.default, log: .data, "method : %@, url: %@", method.rawValue, url)
        #endif
        
        guard var url = URL(string: url) else {
            throw URLError(.badURL)
        }

        var httpBody: Data?

        switch method {
        case .get:
            parameters?.dictionary?.forEach { url.appendQueryItem(name: $0.key, value: $0.value) }
            
        case .post:
            httpBody = try? JSONEncoder().encode(parameters)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.cachePolicy = cachePolicy
        urlRequest.httpBody = httpBody
        
        
        #if DEBUG
        if let allHeaders = urlRequest.allHTTPHeaderFields {
            os_log(.default, log: .data, "-----------------Headers-----------------")
            os_log(.default, log: .data, "%@", allHeaders)
        }
        #endif
        
        let dicParameters = parameters?.dictionary
        #if DEBUG
        os_log(.default, log: .data, "-----------------ParameterConvertible---------------")
        os_log(.default, log: .data, "%@", dicParameters ?? "No Params")
        os_log(.default, log: .data, "🎾==========================================================================🎾")
        #endif
        
        return urlRequest
    }
}


extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}


extension URL {
    mutating func appendQueryItem(name: String, value: Any) {
        guard var urlComponents = URLComponents(string: absoluteString) else { return }
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        let queryItem = URLQueryItem(name: name, value: String(describing: value))
        queryItems.append(queryItem)
        urlComponents.queryItems = queryItems
        self = urlComponents.url!
    }
}

extension OSLog {
    private static var moduleSystem = "com.kor45cw.apikit"
    static let data = OSLog(subsystem: moduleSystem, category: "Data")
}
