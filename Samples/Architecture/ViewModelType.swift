//
//  ViewModelType.swift
//  Samples
//
//  Created by Nguyen Truong Giang on 10/03/2021.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
