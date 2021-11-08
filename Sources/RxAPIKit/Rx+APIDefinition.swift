//
//  Rx+APIDefinition.swift
//  
//
//  Created by kor45cw on 2021/11/08.
//

import APIKit
import RxSwift

public extension APIDefinition {
    @discardableResult
    func request() -> Observable<Response> {
        network.request(urlRequest: try! self.asURLRequest())
    }
}
