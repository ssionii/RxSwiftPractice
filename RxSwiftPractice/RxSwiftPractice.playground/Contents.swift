import UIKit
import RxSwift
import RxCocoa

enum MyError: Error {
    case anError
}


//MARK: - 02_Observables

example(of: "just, of, from") {
    let one = 1
    let two = 2
    let three = 3
    
    let observable: Observable<Int> = Observable<Int>.just(one)
    let observable2 = Observable.of(one, two, three)
    let observable3 = Observable.of([one, two, three])
    let observable4 = Observable.from([one, two, three])
}

example(of: "subscribe") {
    let one = 1
    let two = 2
    let three = 3
    
    let observalbe = Observable.of(one, two, three)
    observalbe.subscribe(onNext: { element in
        print(element)
    })
}

example(of: "empty") {
    let observable = Observable<Void>.empty()
    observable.subscribe(
        onNext: { element in
            print(element)
        },
        onCompleted: {
            print("completed")
        }
    )
}

example(of: "never") {
    let observable = Observable<Any>.never()
    let disposeBag = DisposeBag()
    
    observable.do(
        onSubscribe: {
            print("Subscribed")
        }).subscribe(
            onNext: { element in
                print(element)
            },
            onCompleted: {
                print("Completed")
            }
        )
        .disposed(by: disposeBag)
    
    // 디버그 목적
    observable
        .debug("never 확인")
        .subscribe()
        .disposed(by: disposeBag)
}

example(of: "range") {
    let observable = Observable<Int>.range(start: 1, count: 10)
    observable.subscribe(
        onNext: { i in
            let n = Double(i)
            let fibonacci = Int((pow(1.61803, n) - pow(0.61803, n) / 2.23606).rounded())
            print(fibonacci)
        }
    )
}

example(of: "dispose") {
    let observable = Observable.of("A", "B", "C")
    let subscription = observable.subscribe({ event in
        print(event)
    })
    
    subscription.dispose()
}

example(of: "DisposeBag") {
    let disposeBag = DisposeBag()
    
    Observable.of("A", "B", "C")
        .subscribe{
            print($0)
        }
        .disposed(by: disposeBag) // 이렇게 dispose를 해야 메모리 누수가 안일어남
}

example(of: "create") {
    let disposeBag = DisposeBag()
    
    Observable<String>.create({ observable -> Disposable in
        observable.onNext("1")
        
        observable.onError(MyError.anError)

        observable.onCompleted()
        
        observable.onNext("?")
        
        return Disposables.create()
    })
    .subscribe(
        onNext: { print($0) },
        onError: { print($0) },
        onCompleted: { print("Completed") },
        onDisposed: { print("Disposed") }
    ).disposed(by: disposeBag)
}

example(of: "deferred") {
    let disposeBag = DisposeBag()
    
    var flip = false
    
    let factory: Observable<Int> = Observable.deferred {
        flip = !flip
        
        if flip {
            return Observable.of(1, 2, 3)
        } else {
            return Observable.of(4, 5, 6)
        }
    }
    
    for _ in 0...3 {
        factory.subscribe(onNext: {
            print($0, terminator: "")
        })
        .disposed(by: disposeBag)
        
        print()
    }
}

example(of: "Single") {
    let disposeBag = DisposeBag()
    
    enum FileReadError: Error {
        case fileNotFound, unreadable, encodingFailed
    }
    
    func loadText(from name: String) -> Single<String> {
        return Single.create { single in
            let disposable = Disposables.create()
            
            guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
                single(.failure(FileReadError.fileNotFound))
                return disposable
            }
            
            guard let data = FileManager.default.contents(atPath: path) else {
                single(.failure(FileReadError.unreadable))
                return disposable
            }
            
            guard let contents = String(data: data, encoding: .utf8) else {
                single(.failure(FileReadError.encodingFailed))
                return disposable
            }
            
            single(.success(contents))
            return disposable
            
        }
    }
    
    loadText(from: "Copyright")
        .subscribe {
            switch $0 {
            case .success(let string):
                print(string)
            case .failure(let error):
                print(error)
            }
        }
        .disposed(by: disposeBag)
}

//MARK: - 03_Subjects

example(of: "PublishSubject") {
    let subject = PublishSubject<String>()
    
    subject.onNext("Is anyone listening?")
    
    // next 이벤트가 발생했을 때 어떻게 할 건지 정의 해둠
    let subscriptionOne = subject
        .subscribe(onNext: { string in // subscribe로 구독 !
            print(string)
        })
    
    // next 이벤트 발생시키기
    subject.onNext("1")
}

example(of: "PublishSubject") {
    // subject 생성
    let subject = PublishSubject<String>()
    subject.onNext("Is anyone listening?")
    
    // subject를 구독하고 next 이벤트가 왔을 때 어떻게 처리할지 정의
    let subscriptionOne = subject
        .subscribe(onNext: { string in
            print(string)
        })
    subject.onNext("1")
    subject.onNext("2")
    
    // subject를 구독하고 이벤트가 왔을 때 어떻게 처리할지 정의
    let subscriptionTwo = subject
        .subscribe({ event in
            print("2)", event.element ?? event)
        })
    
    subject.onNext("3")

    // subscriptionOne dispose
    subscriptionOne.dispose()
    subject.onNext("4")
    
    // subject 끝 ! 이제 방출 안할거다 !
    // subject는 이러한 종료 이벤트들을 이후 새로운 subscriber들에게 재방출한다 ! (subject가 작동하는 것은 x)
    subject.onCompleted()
    
    subject.onNext("5")
    
    // subscriptionTwo dispose
    subscriptionTwo.dispose()
    
    // 쓰레기통 만들기
    let disposeBag = DisposeBag()
    
    // subject를 구독하고 이벤트가 왔을 때 어떻게 처리할지 정의
    subject
        .subscribe { event in
            print("3)", event.element ?? event)
        }
        .disposed(by: disposeBag) // 일일히 dispose 하지 않고, observable에 대해 subscribing하고 이것을 즉히 쓰레기통에 추가
    
    subject.onNext("?")
}

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
    print(label, event.element ?? event.error ?? event)
}

example(of: "BehaviorSubject") {
    
    // BehaviorSubject는 항상 최신의 값을 방출하기 때문에 초기값 없이는 만들 수 없다. 반드시 초기값이 있어야 함
    let subject = BehaviorSubject(value: "Initial value")
    let disposeBag = DisposeBag()
    
    subject.onNext("X")
    subject
        .subscribe { event in
            print(label: "1)", event: event)
        }
        .disposed(by: disposeBag)
    
    subject.onError(MyError.anError)
    
    subject
        .subscribe { event in
            print(label: "2)", event: event)
        }
        .disposed(by: disposeBag)
}

example(of: "ReplaySubject") {
    let subject = ReplaySubject<String>.create(bufferSize: 2)
    let disposeBag = DisposeBag()
    
    subject.onNext("1")
    subject.onNext("2")
    subject.onNext("3")
    
    subject
        .subscribe { event in
            print(label: "1)", event: event)
        }
        .disposed(by: disposeBag)
    
    subject
        .subscribe { event in
            print(label: "2)", event: event)
        }
        .disposed(by: disposeBag)
    
    subject.onNext("4")
    
    subject.onError(MyError.anError)
    
    subject.dispose()
    
    subject
        .subscribe { event in
            print(label: "3)", event: event)
        }
        .disposed(by: disposeBag)
}


//MARK: - 04_Filtering Operators

example(of: "ignoreElements") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    strikes
        .ignoreElements()
        .subscribe({ _ in
            print("You're out!")
        })
        .disposed(by: disposeBag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    
    strikes.onCompleted()
}


example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    strikes
        .element(at: 2)
        .subscribe(onNext: { _ in
            print("You're out!")
        })
        .disposed(by: disposeBag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
}

example(of: "filter") {
    let disposeBag = DisposeBag()
    
    Observable.of(1, 2, 3, 4, 5, 6)
        .filter({ number -> Bool in
            number % 2 == 0
        })
        .subscribe(onNext: { even in
            print(even)
        })
        .disposed(by: disposeBag)
}

example(of: "skip") {
    let disposeBag = DisposeBag()
    
    Observable.of("A", "B", "C", "D", "E", "F")
        .skip(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

// skip 하지 않을 때 까지 skip.
// 한번 skip이 안되면 그 이후부터는 skip이 없어진다고 생각하면 된다.
example(of: "skipWhile") {
    let disposeBag = DisposeBag()
    
    Observable.of(2, 2, 3, 4, 4)
        .skip(while: { number -> Bool in
            number % 2 == 0
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "skipUntil") {
    let disposeBag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .skip(until: trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    subject.onNext("A")
    subject.onNext("B")
    
    trigger.onNext("X")
    
    subject.onNext("C")
}

example(of: "takeWhile") {
    let disposeBag = DisposeBag()
    
    Observable.of(2, 2, 4, 4, 6, 6)
        .enumerated()
        .take(while: { index, value in
            value % 2 == 0 && index < 3
        })
        .map { $0.element }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "distincUntilChaged") {
    let disposeBag = DisposeBag()
    
    Observable.of("A", "A", "B", "B", "A")
        .distinctUntilChanged()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "challenge"){
    
    let contacts = [
      "603-555-1212": "Florent",
      "212-555-1212": "Shai",
      "408-555-1212": "Marin",
      "617-555-1212": "Scott"
    ]
    
    
    func phoneNumber(from inputs: [Int]) -> String {
        var phone = inputs.map(String.init).joined()
        
        phone.insert("-", at: phone.index(phone.startIndex, offsetBy: 3))
        phone.insert("-", at: phone.index(phone.startIndex, offsetBy: 7))
        
        return phone
    }
    
    let input = PublishSubject<Int>()
    let disposeBag = DisposeBag()
    
    input
        .skip(while: { number -> Bool in
            number == 0
        })
        .filter { number -> Bool in
            number < 10
        }
        .take(10)
        .toArray()
        .subscribe(onSuccess: {
            let phone = phoneNumber(from: $0)
            
            if let contact = contacts[phone] {
                print("Dialing \(contact) (\(phone))...")
            } else {
                print("Contact not found")
            }
        })
        .disposed(by: disposeBag)
    
    input.onNext(0)
    input.onNext(603)
    
    input.onNext(2)
    input.onNext(1)
    
    
    input.onNext(7)
    
    "5551212".forEach {
        if let number = (Int("\($0)")) {
            input.onNext(number)
        }
    }
    
    input.onNext(9)
}

//MARK: - 07_Transforming Operators

example(of: "toArray") {
    let disposeBag = DisposeBag()
    
    Observable.of("A", "B", "C")
        .toArray()
        .subscribe({
            print($0)
        })
        .disposed(by: disposeBag)
}


example(of: "map") {
    let disposeBag = DisposeBag()
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(123, 4, 56)
        .map {
            formatter.string(from: $0) ?? ""
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "enumerated and map") {
    let disposeBag = DisposeBag()
    
    Observable.of(1,2, 3, 4, 5, 6)
        .enumerated()
        .map { index, integer in
            index > 2 ? integer * 2 : integer
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

struct Student {
    var score: BehaviorSubject<Int>
}

example(of: "flatMap") {
    let disposeBag = DisposeBag()
    
    let ryan = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 90))
    
    let student = PublishSubject<Student>()
    
    student
        .flatMap {
            $0.score
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    student.onNext(ryan) // 80
    ryan.score.onNext(85) // 80 85
    student.onNext(charlotte) // 80 85 90
    ryan.score.onNext(95)
    charlotte.score.onNext(100)
}

example(of: "flatMapLatest") {
    let disposeBag = DisposeBag()
    
    let ryan = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 90))
    
    let student = PublishSubject<Student>()
    
    student
        .flatMapLatest {
            $0.score
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    student.onNext(ryan)
    ryan.score.onNext(85)
    
    student.onNext(charlotte)
    
    ryan.score.onNext(95) // flatMapLatest가 이미 charlotte의 최근 observable로 전환했기 때문에 ryan의 점수인 95는 반영 X
    charlotte.score.onNext(100)
    
}

example(of: "materialize and dematerialize") {
    
    let disposeBag = DisposeBag()
    
    let ryan = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 100))
    
    let student = BehaviorSubject(value: ryan)
    
    let studentScore = student
        .flatMapLatest {
            $0.score.materialize()
        }
    
    studentScore
        .filter {
            guard $0.error == nil else {
                print($0.error!)
                return false
            }

            return true
        }
        .dematerialize()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    ryan.score.onNext(85)
    ryan.score.onError(MyError.anError)
    ryan.score.onNext(90)
    
    student.onNext(charlotte)
}

example(of: "Challenge ") {
    let disposeBag = DisposeBag()
    
    let contacts = [
      "603-555-1212": "Florent",
      "212-555-1212": "Shai",
      "408-555-1212": "Marin",
      "617-555-1212": "Scott"
    ]
    
    let convert: (String) -> Int? = { value in
        if let number = Int(value),
           number < 10 {
            return number
        }
        
        let keyMap: [String: Int] = [
          "abc": 2, "def": 3, "ghi": 4,
          "jkl": 5, "mno": 6, "pqrs": 7,
          "tuv": 8, "wxyz": 9
        ]
        
        let converted = keyMap
            .filter { $0.key.contains(value.lowercased()) }
            .map(\.value)
            .first
        
        return converted
    }
    
    let format: ([Int]) -> String = {
        var phone = $0.map(String.init).joined()
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 3)
        )
        phone.insert("-", at: phone.index(
          phone.startIndex,
          offsetBy: 7)
        )
        
        return phone
    }
    
    let dial: (String) -> String = {
      if let contact = contacts[$0] {
        return "Dialing \(contact) (\($0))..."
      } else {
        return "Contact not found"
      }
    }
    
    let input = PublishSubject<String>()
    
    input.asObservable()
        .map(convert)
        .flatMap {
            $0 == nil ? Observable.empty() : Observable.just($0!)
        }
        .skip(while: {$0 == 0})
        .take(10)
        .toArray()
        .map(format)
        .map(dial)
        .subscribe(onSuccess: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    input.onNext("")
    input.onNext("0")
    input.onNext("408")
    
    input.onNext("6")
    input.onNext("")
    input.onNext("0")
    input.onNext("3")
    
    "JKL1A1B".forEach {
      input.onNext("\($0)")
    }
    
    input.onNext("9")
    
    
}
