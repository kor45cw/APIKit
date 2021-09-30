//
//  NetworkProtocol.swift
//  
//
//  Created by kor45cw on 2021/09/30.
//

import Foundation
import Combine

public protocol NetworkProtocol: AnyObject {
    func request<T: Decodable>(urlRequest: URLRequest) -> AnyPublisher<T, Error>
    func request<T: Decodable>(urlRequest: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
}
