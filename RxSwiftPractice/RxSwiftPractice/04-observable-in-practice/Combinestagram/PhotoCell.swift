//
//  PhotoCell.swift
//  RxSwiftPractice
//
//  Created by  60117280 on 2021/03/25.
//

import UIKit

class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    var representedAssetIdentifier: String!

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
  }

  func flash() {
    imageView.alpha = 0
    setNeedsDisplay()
    UIView.animate(withDuration: 0.5, animations: { [weak self] in
      self?.imageView.alpha = 1
    })
  }
}
