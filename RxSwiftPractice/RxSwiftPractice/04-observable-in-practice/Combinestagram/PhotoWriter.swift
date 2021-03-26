//
//  PhotoWriter.swift
//  RxSwiftPractice
//
//  Created by  60117280 on 2021/03/25.
//

import Foundation
import UIKit
import RxSwift
import Photos

class PhotoWriter {
    enum Errors: Error {
      case couldNotSavePhoto
    }
    
    static func save(_ image: UIImage) -> Single<String> {
        return Single.create(subscribe: { observer in
            var savedAssetId: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success, let id = savedAssetId {
                        observer(.success(id))
                    } else {
                        observer(.failure(error ?? Errors.couldNotSavePhoto))
                    }
                }
            })
            return Disposables.create()
        })
    }
}
