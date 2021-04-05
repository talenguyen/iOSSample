//
//  SampleViewModelTests.swift
//  SampleViewModelTests
//
//  Created by Nguyen Truong Giang on 10/03/2021.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking

// NOTE 1: @testable import
@testable import Samples

// NOTE 4: Mock & Stub
struct MockApiService: ApiService {
    static var index = 0
    let results: [[String]]
    
    func fetch() -> Single<[String]> {
        if (MockApiService.index >= results.count) {
            MockApiService.index = 0
        }
        let result = results[MockApiService.index]
        MockApiService.index += 1
        if (result.count == 0) {
            return Single.error(NSError(domain: "empty", code: -1, userInfo: nil))
        }
        return Single.just(result)
    }
}

class SampleViewModelTests: XCTestCase {
    // NOTE 3: setUp & tearDown
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    var sut: SampleViewModel!

    // NOTE 2: setUp & tearDown
    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
        scheduler = nil
        disposeBag = nil
        MockApiService.index = 0
        super.tearDown()
    }

    func testSuccess() throws {
        // given
        let result1 = ["1", "2"]
        let result2 = ["3", "4"]
        
        sut = SampleViewModel(apiService: MockApiService(results: [result1, result2]))
        
        // NOTE 5: TestScheduler
        let refresh = scheduler.createColdObservable([.next(100, ()), .next(200, ())])
        
        let input = SampleViewModel.Input(refreshStream: refresh.asDriver(onErrorJustReturn: ()), itemPositionSelectStream: Driver.empty())
        let output = sut.transform(input: input)
        
        let items = scheduler.createObserver([String].self)
        
        output.itemsStream
            .drive(items)
            .disposed(by: disposeBag)
        
        // when
        scheduler.start()
        
        // NOTE 5: Verify
        // then
        XCTAssertEqual(items.events, [.next(100, result1),.next(200, result2)])
    }

    func testErrorThenSuccess() throws {
        // given
        let result1: [String] = []
        let result2 = ["1", "2"]
        
        sut = SampleViewModel(apiService: MockApiService(results: [result1, result2]))
        
        let refresh = scheduler.createColdObservable([.next(100, ()), .next(200, ())])
        
        let input = SampleViewModel.Input(refreshStream: refresh.asDriver(onErrorJustReturn: ()), itemPositionSelectStream: Driver.empty())
        let output = sut.transform(input: input)
        
        let items = scheduler.createObserver([String].self)
        
        output.itemsStream
            .drive(items)
            .disposed(by: disposeBag)
        
        // when
        scheduler.start()
        
        // then
        XCTAssertEqual(items.events, [.next(100, result1),.next(200, result2)])
    }

    func testSelectItem() throws {
        // given
        
        sut = SampleViewModel(apiService: MockApiService(results: [["1", "2", "3"]]))
        
        let refresh = scheduler.createColdObservable([.next(100, ())])
        let selectedIndex = scheduler.createColdObservable([.next(200, 1)]) // select at position: 1
        
        let input = SampleViewModel.Input(refreshStream: refresh.asDriver(onErrorJustReturn: ()), itemPositionSelectStream: selectedIndex.asDriver(onErrorJustReturn: 0))
        
        let output = sut.transform(input: input)
        
        let selectedItem = scheduler.createObserver(String.self)
        
        output.selectedItemStream
            .drive(selectedItem)
            .disposed(by: disposeBag)
        
        // when
        scheduler.start()
        
        // then
        XCTAssertEqual(selectedItem.events, [.next(200, "2")])
    }
}
