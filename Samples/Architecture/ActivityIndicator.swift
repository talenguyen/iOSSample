import RxSwift
import RxCocoa

private struct ActivityToken<E>: ObservableConvertibleType, Disposable {
    private let _source: Observable<E>
    private let _dispose: Cancelable

    init(source: Observable<E>, disposeAction: @escaping () -> Void) {
        _source = source
        _dispose = Disposables.create(with: disposeAction)
    }

    func dispose() {
        _dispose.dispose()
    }

    func asObservable() -> Observable<E> {
        _source
    }
}

/**
Enables monitoring of sequence computation.
If there is at least one sequence computation in progress, `true` will be sent.
When all activities complete `false` will be sent.
*/
public class ActivityIndicator: SharedSequenceConvertibleType {
    public typealias Element = Bool
    public typealias SharingStrategy = DriverSharingStrategy

    private let _lock = NSRecursiveLock()
    private let _relay = BehaviorRelay(value: 0)
    private let _loading: SharedSequence<SharingStrategy, Bool>

    public init() {
        _loading = _relay.asDriver()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }

    fileprivate func trackActivityOfObservable<Source: ObservableConvertibleType>(_ source: Source) -> Observable<Source.Element> {
        return Observable.using { () -> ActivityToken<Source.Element> in
            self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        } observableFactory: { t in
            return t.asObservable()
        }
    }

    private func increment() {
        _lock.lock()
        _relay.accept(_relay.value + 1)
        _lock.unlock()
    }

    private func decrement() {
        _lock.lock()
        _relay.accept(_relay.value - 1)
        _lock.unlock()
    }

    public func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
        _loading
    }
}

extension ObservableConvertibleType {
    public func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
        activityIndicator.trackActivityOfObservable(self)
    }
}


protocol ActivityTrackingProtocol {
    var indicator: ActivityIndicator { get set }
}


extension ActivityTrackingProtocol {
    var indicator: ActivityIndicator {
        get {
            guard let r = objc_getAssociatedObject(self, &Loading.name) as? ActivityIndicator else {
                let new = ActivityIndicator()
                objc_setAssociatedObject(self, &Loading.name, new, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return new
            }
            return r
        }
        set {
            objc_setAssociatedObject(self, &Loading.name, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


private enum Loading {
    static var name = "indicatorProgress"
}

extension ActivityTrackingProtocol {
    var loadingProgress: Observable<ActivityIndicator.Element> {
        return indicator.asObservable().observeOn(MainScheduler.asyncInstance)
    }
}
