//
//  BusinessListingCell.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-22.
//

import UIKit

class BusinessListingCell: UITableViewCell {
    
    static let reuseIdentifier = "BusinessListingCell"
    
    let designView = BusinessListingView()
    
    var business: YelpBusiness? {
        get { designView.business }
        set { designView.business = newValue }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        includeDesignView()
        configureLayoutConstraints()
    }
    
    override func prepareForReuse() {
        self.business = nil
        super.prepareForReuse()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayoutConstraints() {
        NSLayoutConstraint.activate([
            designView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            designView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            designView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            designView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
    
    private func includeDesignView() {
        designView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(designView)
    }
}
