//
//  SampleViewModel.swift
//  Samples
//
//  Created by Nguyen Truong Giang on 10/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

final class SampleViewModel: ViewModelType {
    
    struct Input {
        let refreshStream: Driver<Void>
        let itemPositionSelectStream: Driver<Int>
    }
    
    struct Output {
        let refreshingStream: Driver<Bool>
        let itemsStream: Driver<[String]>
        let selectedItemStream: Driver<String>
    }
    
    let apiService: ApiService
    
    init(apiService: ApiService) {
        self.apiService = apiService
    }
    
    func transform(input: Input) -> Output {
        let refreshing = ActivityIndicator()
        
        let items = input.refreshStream
            .flatMapLatest { _ in
                self.apiService.fetch()
                    .trackActivity(refreshing)
                    .asDriver(onErrorJustReturn: [])
            }
        
        let selectedItem = input.itemPositionSelectStream
            .withLatestFrom(items) { index, items in
                return items[index]
            }
        
        return Output(refreshingStream: refreshing.asDriver(), itemsStream: items, selectedItemStream: selectedItem)
    }
}
