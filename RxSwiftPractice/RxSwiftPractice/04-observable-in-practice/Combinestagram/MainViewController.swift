//
//  MainViewController.swift
//  RxSwiftPractice
//
//  Created by  60117280 on 2021/03/25.
//

import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {

    private let bag = DisposeBag()
    private let images = BehaviorRelay<[UIImage]>(value: [])

    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        images.asObservable()
            .subscribe(onNext: { [weak imagePreview] photos in
                guard let preview = imagePreview else { return }
                preview.image = photos.collage(size: preview.frame.size)
            })
            .disposed(by: bag)
        
        images.asObservable()
            .subscribe(onNext: { [weak self] photos in
                self?.updateUI(photos: photos)
            })
            .disposed(by: bag)
        
    }

    @IBAction func actionAdd(_ sender: Any) {
        let photoViewController = storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        photoViewController.selectedPhotos
            .subscribe(
                onNext: { [weak self] newImage in
                    guard let images = self?.images else { return }
                    images.accept(images.value + [newImage])
                },
                onDisposed: {
                    print("Completed photo selection")
                }
            )
            .disposed(by: bag)
        
        self.navigationController?.pushViewController(photoViewController, animated: true)
    }
    
    @IBAction func actionClear() {
        images.accept([])
    }
    
    @IBAction func actionSave(_ sender: UIButton) {
        guard let image = imagePreview.image else { return }
        
        PhotoWriter.save(image)
            .subscribe(
                onSuccess: { [weak self] id in
                    self?.showMessage("Saved with id: \(id)")
                    self?.actionClear()
                },
                onFailure: { [weak self] error in
                    self?.showMessage("Error", description: error.localizedDescription)
                })
            .disposed(by: bag)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        alert(title: title, text: description)
            .subscribe()
            .disposed(by: bag)
    }
    
    func updateUI(photos: [UIImage]) {
        saveButton.isEnabled = photos.count > 0 && photos.count % 2 == 0
        clearButton.isEnabled = photos.count > 0
        addButton.isEnabled = photos.count < 6
        navigationBar.title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
}

extension UIViewController {
    func alert(title: String, text: String?) -> Completable {
        return Completable.create(subscribe: { [weak self] completable in
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .default, handler: { _ in
                completable(.completed)
            })
            alert.addAction(closeAction)
            self?.present(alert, animated: true, completion: nil)
            return Disposables.create {
                self?.dismiss(animated: true, completion: nil)
            }
        })
    }
}
