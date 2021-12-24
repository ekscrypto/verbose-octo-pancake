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
    
    enum Style {
        static let ratingCornerRadius: CGFloat = 6.0
        static let ratingOpacity: CGFloat = 0.7
        static let ratingPadding: CGFloat = 25.0
        static let ratingWidthRatio: CGFloat = 0.2
        static let labelPadding: CGFloat = 25.0
    }
    
    private let imageView: UIImageView = prepareImageView()
    private let nameLabelReferenceView: UIView = prepareNameLabelReferenceView()
    private let nameLabel: UILabel = prepareNameLabel()
    private let ratingLabel: UILabel = prepareRatingLabel()
    private lazy var designed: Bool = self.implementDesign()
    
    override func layoutSubviews() {
        _ = designed
        super.layoutSubviews()
    }
    
    private func implementDesign() -> Bool {
        constructViewLayout()
        configureLayoutConstraints()
        return true
    }
    
    private func constructViewLayout() {
        [nameLabel, nameLabelReferenceView, ratingLabel, imageView]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        self.addSubview(imageView)
        self.addSubview(ratingLabel)
        self.addSubview(nameLabelReferenceView)
        self.addSubview(nameLabel)
        self.clipsToBounds = true
    }
    
    private func configureLayoutConstraints() {
        NSLayoutConstraint.activate([
            ratingLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: Style.ratingWidthRatio),
            ratingLabel.heightAnchor.constraint(equalTo: ratingLabel.widthAnchor),
            ratingLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Style.ratingPadding),
            ratingLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -Style.ratingPadding),
            
            imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: self.rightAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            nameLabelReferenceView.topAnchor.constraint(equalTo: self.topAnchor, constant: Style.ratingPadding),
            nameLabelReferenceView.bottomAnchor.constraint(equalTo: ratingLabel.topAnchor, constant: -Style.labelPadding),
            nameLabelReferenceView.widthAnchor.constraint(equalTo: ratingLabel.widthAnchor),
            nameLabelReferenceView.centerXAnchor.constraint(equalTo: ratingLabel.centerXAnchor),
            
            nameLabel.centerXAnchor.constraint(equalTo: nameLabelReferenceView.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: nameLabelReferenceView.centerYAnchor)
        ])
    }
    
    private static func prepareNameLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .label
        label.alpha = Style.ratingOpacity
        label.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi / 2.0, 0, 0, 1)
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.5)
        return label
    }
    
    private static func prepareNameLabelReferenceView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = Style.ratingCornerRadius
        view.layer.masksToBounds = true
        view.alpha = Style.ratingOpacity
        return view
    }
    
    private static func prepareRatingLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = .systemGray6
        label.textColor = .label
        label.font = .systemFont(ofSize: UIFont.systemFontSize * 2.0)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.layer.cornerRadius = Style.ratingCornerRadius
        label.layer.masksToBounds = true
        label.alpha = Style.ratingOpacity
        return label
    }
    
    private static func prepareImageView() -> UIImageView {
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
        imageView.image = nil
        guard let imageUrlString = business?.imageUrl,
              !imageUrlString.isEmpty,
              let imageUrl = URL(string: imageUrlString)
        else {
            return
        }
        
        let urlRequest = URLRequest(url: imageUrl, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20.0)
        URLSession.shared.dataTask(with: urlRequest, completionHandler: { [weak self] dataOrNil, urlResponseOrNil, errorOrNil in
            guard let httpResponse = urlResponseOrNil as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = dataOrNil,
                  data.count > 0
            else {
                return
            }
            DispatchQueue.main.async { self?.updateImage(imageData: data, origin: imageUrlString) }
        }).resume()
    }
    
    private func updateImage(imageData: Data, origin: String) {
        guard business?.imageUrl == origin else {
            return
        }
        imageView.image = UIImage(data: imageData)
    }
}
