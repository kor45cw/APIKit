//
//  Publisher+Extension.swift
//  
//
//  Created by kor45cw on 2021/10/11.
//

import Foundation
import Combine
import OSLog


extension Publisher where Self.Output == Data {
    func log(file: StaticString = #file,
             function: StaticString = #function,
             line: Int = #line,
             message: String? = nil) -> AnyPublisher<Self.Output, Self.Failure> {
        self.map {
            let message = """
            [🤖⚠️Log]
            \(file):\(line) --> \(function)
            [👇 Self.Output]
            \(String(describing: String(data: $0, encoding: .utf8)))
            """
            os_log("%@", log: .default, type: .default, message)
            return $0
        }.eraseToAnyPublisher()
    }
}
