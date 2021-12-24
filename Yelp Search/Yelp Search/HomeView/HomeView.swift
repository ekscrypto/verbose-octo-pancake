//
//  HomeView.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-22.
//

import UIKit

protocol HomeViewCompatible: UIView {
    var tableView: UITableView { get }
    var onSearchLocation: (String) -> Void { get set }
    var showActivity: Bool { get set }
}

final class HomeView: UIView, HomeViewCompatible, UITextFieldDelegate {
    
    // Interfaces exposed to view controller
    let tableView: UITableView = prepareTableView()
    var onSearchLocation: (String) -> Void = { _ in /* by default do nothing */ }
    var showActivity: Bool = false {
        didSet {
            if showActivity {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    enum Style {
        static let activityIndicatorPadding: CGFloat = 15.0
        static let searchTextFieldHeight: CGFloat = 40.0
        static let searchTextFieldSideMargins: CGFloat = 15.0
        static let yelpLogoOpacity: CGFloat = 1.0
    }

    private lazy var designed: Bool = implementDesign()
    private let activityIndicator: UIActivityIndicatorView = prepareActivityIndicator()
    private var keyboardAnimator: KeyboardAnimator?
    private var keyboardHeightConstraint: NSLayoutConstraint?
    private lazy var searchTextField: UITextField = prepareSearchTextField()
    private let searchContainer: UIView = prepareSearchContainer()
    private let yelpLogoImageView: UIImageView = prepareYelpLogoImageView()
    
    override func layoutSubviews() {
        _ = designed
        super.layoutSubviews()
    }
    
    private func implementDesign() -> Bool {
        self.backgroundColor = .systemBackground
        constructViewLayout()
        configureLayoutConstraints()
        observeKeyboardAppearance()
        monitorTapOutsideSearchField()
        return true
    }
    
    private func constructViewLayout() {
        [activityIndicator, searchContainer, searchTextField, tableView, yelpLogoImageView]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        self.addSubview(searchContainer)
        self.addSubview(yelpLogoImageView)
        self.addSubview(tableView)
        self.addSubview(activityIndicator)
        searchContainer.addSubview(searchTextField)
    }
    
    private func configureLayoutConstraints() {
        let keepSearchContainerSmallConstraint = searchContainer.heightAnchor.constraint(equalToConstant: 0)
        keepSearchContainerSmallConstraint.priority = UILayoutPriority(1)
        keyboardHeightConstraint = self.bottomAnchor.constraint(greaterThanOrEqualTo: searchTextField.bottomAnchor, constant: 0)
        keyboardHeightConstraint?.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            keepSearchContainerSmallConstraint,
            searchContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            searchContainer.topAnchor.constraint(equalTo: searchTextField.topAnchor),
            searchContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            searchContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            searchTextField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: Style.searchTextFieldSideMargins),
            searchTextField.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -Style.searchTextFieldSideMargins),
            searchTextField.bottomAnchor.constraint(lessThanOrEqualTo: self.safeAreaLayoutGuide.bottomAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: Style.searchTextFieldHeight),
            
            tableView.bottomAnchor.constraint(equalTo: searchContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            
            yelpLogoImageView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            yelpLogoImageView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            yelpLogoImageView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            yelpLogoImageView.heightAnchor.constraint(equalTo: yelpLogoImageView.widthAnchor),
            
            activityIndicator.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: Style.activityIndicatorPadding),
            activityIndicator.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            
            keyboardHeightConstraint!
        ])
    }
    
    private static func prepareActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.tintColor = .systemGray3
        return activityIndicator
    }
    
    private static func prepareTableView() -> UITableView {
        let view = UITableView()
        view.insetsContentViewsToSafeArea = true
        view.clipsToBounds = true
        view.keyboardDismissMode = .onDrag
        view.backgroundColor = .clear
        return view
    }
    
    private static func prepareSearchContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemFill
        return view
    }
    
    private func prepareSearchTextField() -> UITextField {
        let textField = UITextField()
        textField.addTarget(self, action: #selector(searchTextFieldChanged(_:)), for: .editingChanged)
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .yes
        textField.clearButtonMode = .always
        textField.clearsOnBeginEditing = true
        textField.enablesReturnKeyAutomatically = true
        textField.keyboardType = .alphabet
        textField.textColor = .label
        textField.tintColor = .label
        textField.placeholder = "Enter a location to search…"
        textField.backgroundColor = .clear
        return textField
    }
    
    private static func prepareYelpLogoImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "YelpLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.alpha = Style.yelpLogoOpacity
        return imageView
    }
    
    @objc
    private func searchTextFieldChanged(_: UITextField) {
        onSearchLocation(searchTextField.text ?? "")
    }
    
    private func observeKeyboardAppearance() {
        guard let constraintToAdjust = keyboardHeightConstraint else {
            fatalError("Invalid initialization sequence, make sure constraint is initialized")
        }
        keyboardAnimator = KeyboardAnimator(animatedConstraint: constraintToAdjust, adjustedView: self)
    }
    
    private func monitorTapOutsideSearchField() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onUserTapOutsideSearchField(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func onUserTapOutsideSearchField(_: UIGestureRecognizer) {
        searchTextField.endEditing(true)
    }
}
