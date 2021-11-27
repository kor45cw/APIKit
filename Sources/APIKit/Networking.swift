//
//  Networking.swift
//  
//
//  Created by kor45cw on 2021/09/30.
//

import Foundation
import Combine


struct EmptyEncodable: Encodable {}
struct EmptyDecodable: Decodable {}

let serialQueue = DispatchQueue(label: "netwoking", qos: .background)

public enum NetworkingError: Error {
    case noData
    case parseError(jsonString: String)
}

internal class Networking {
    public static let `default` = Networking()
}

extension Networking: NetworkProtocol {
    public func request<T>(urlRequest: URLRequest,
                           decoder: JSONDecoder) -> AnyPublisher<T, Error> where T : Decodable {
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .subscribe(on: serialQueue)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                          throw URLError(.badServerResponse)
                      }
                return element.data
            }
            .log()
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func request<T>(urlRequest: URLRequest, decoder: JSONDecoder, completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        serialQueue.async {
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let response = response,
                      (200..<300).contains((response as? HTTPURLResponse)?.statusCode ?? 0) else {
                          completion(.failure(URLError(.badServerResponse)))
                          return
                      }
                
                guard let data = data else {
                    completion(.failure(NetworkingError.noData))
                    return
                }
                
                guard let output = try? decoder.decode(T.self, from: data) else {
                    let jsonString = String(decoding: data, as: UTF8.self)
                    completion(.failure(NetworkingError.parseError(jsonString: jsonString)))
                    return
                }
                
                completion(.success(output))
            }.resume()
        }
    }
    
    @available(iOS 15.0.0, *)
    public func request<T>(urlRequest: URLRequest, decoder: JSONDecoder) async throws -> T where T : Decodable {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard (200..<300).contains((response as? HTTPURLResponse)?.statusCode ?? 0) else {
            throw URLError(.badServerResponse)
        }
        
        let output = try decoder.decode(T.self, from: data)
        
        return output
    }
}
