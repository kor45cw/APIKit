//
//  Rx+NetworkProtocol.swift
//  
//
//  Created by kor45cw on 2021/09/30.
//

import APIKit
import RxSwift
import Foundation


public extension NetworkProtocol {
    func request<T: Decodable>(urlRequest: URLRequest) -> Observable<T> {
        .create { observer in
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let response = response,
                      (200..<300).contains((response as? HTTPURLResponse)?.statusCode ?? 0) else {
                          observer.onError(URLError(.badServerResponse))
                          return
                      }
                
                guard let data = data else {
                    observer.onError(NetworkingError.noData)
                    return
                }
                
                guard let output = try? JSONDecoder().decode(T.self, from: data) else {
                    observer.onError(NetworkingError.parseError)
                    return
                }
                observer.onNext(output)
            }.resume()
            
            
            return Disposables.create()
        }
    }
}
