//
//  ApiService.swift
//  Samples
//
//  Created by Nguyen Truong Giang on 10/03/2021.
//

import Foundation
import RxSwift

protocol ApiService {
    func fetch() -> Single<[String]>
}
