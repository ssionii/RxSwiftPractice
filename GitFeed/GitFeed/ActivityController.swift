//
//  ActivityController.swift
//  GitFeed
//
//  Created by  60117280 on 2021/03/29.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

func cachedFileURL(_ fileName: String) -> URL {
    return FileManager.default
        .urls(for: .cachesDirectory, in: .allDomainsMask)
        .first!
        .appendingPathComponent(fileName)
}

class ActivityController: UITableViewController {
    private let repo = "ReactiveX/RxSwift"
    
    private let events = BehaviorRelay<[Event]>(value: [])
    private let bag = DisposeBag()
    private let eventsFileURL = cachedFileURL("event.plist")
    private let modifiedFileURL = cachedFileURL("modified.txt")
    private let lastModified = BehaviorRelay<String?>(value: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = repo
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        if let lastModifiedString = try? String(contentsOf: modifiedFileURL, encoding: .utf8) {
            lastModified.accept(lastModifiedString)
        }
        
        refresh()
    }
    
    @objc func refresh() {
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }
            self.fetchEvents(repo: self.repo)
        }
    }
    
    func fetchEvents(repo: String) {
        let response = Observable.from([repo])
            .map { urlString -> URL in
                return URL(string: "https://api.github.com/repos/\(urlString)/events")!
            }
            .map { [weak self] url -> URLRequest in
                var request = URLRequest(url: url)
                if let modifiedHeader = self?.lastModified.value {
                    request.addValue(modifiedHeader as String, forHTTPHeaderField: "Last-Modified")
                }
                return request
            }
            .flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
                return URLSession.shared.rx.response(request: request)
            }
            .share(replay: 1, scope: .whileConnected)
        // URLSession.rx.response(request:)는 서버로 리퀘스트를 보내고 리스폰스를 받으면 받은 데이터를 .next 이벤트를 통해 단 한번만 방출한 뒤 complete 된다.
        
        response
            .filter { response, _ in
                return 200..<300 ~= response.statusCode
            }
            .compactMap { _, data -> [Event]? in
                return try? JSONDecoder().decode([Event].self, from: data)
            }
            .subscribe(onNext: { [weak self] newEvents in
                print(newEvents)
                self?.processEvents(newEvents)
            })
            .disposed(by: bag)
        
        
        response
            .filter { response, _ in
                return 200..<400 ~= response.statusCode
            }
            .flatMap { response, _ -> Observable<String> in
                guard let value = response.allHeaderFields["Last-Modified"] as? String else {
                    return Observable.empty()
                }
                return Observable.just(value)
            }
            .subscribe(onNext: { [weak self] modifiedHeader in
                guard let strongSelf = self else { return }
                strongSelf.lastModified.accept(modifiedHeader)
                try? modifiedHeader.write(to: strongSelf.modifiedFileURL, atomically: true, encoding: .utf8)
            })
            .disposed(by: bag)

    }
    
    func processEvents(_ newEvents: [Event]) {
        var updatedEvents = newEvents + events.value
        if updatedEvents.count > 50 {
            updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
        }
        
        events.accept(updatedEvents)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
        let encoder = JSONEncoder()
        if let eventsData = try? encoder.encode(updatedEvents) {
            try? eventsData.write(to: eventsFileURL, options: .atomicWrite)
        }
    }
    
    // MARK: - Table Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events.value[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = event.actor.name
        cell.detailTextLabel?.text = event.repo.name + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
        cell.imageView?.kf.setImage(with: event.actor.avatar, placeholder: UIImage(named: "blank-avatar"))
        return cell
    }
}
