//
//  BusinessListingView.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-22.
//

import UIKit

class BusinessListingView: UIView {
    
    var business: YelpBusiness? {
        didSet {
            updateContent()
        }
    }
    
    private lazy var nameLabel = prepareNameLabel()
    private lazy var ratingLabel = prepareRatingLabel()
    private lazy var imageView = prepareImageView()
    private lazy var designed: Bool = self.implementDesign()
    
    override func layoutSubviews() {
        _ = designed
        super.layoutSubviews()
    }
    
    private func implementDesign() -> Bool {
        self.backgroundColor = .blue
        return true
    }
    
    private func prepareNameLabel() -> UILabel {
        UILabel()
    }
    
    private func prepareRatingLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: UIFont.systemFontSize * 2.0)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }
    
    private func prepareImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    private func updateContent() {
        updateRating()
        updateName()
        updateImage()
    }
    
    private func updateRating() {
        ratingLabel.text = String(format: "%.1f", business?.rating ?? 0.0)
    }
    
    private func updateName() {
        nameLabel.text = business?.name
    }
    
    private func updateImage() {
        
    }
}
