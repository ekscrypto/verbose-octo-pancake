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
}

final class HomeView: UIView, HomeViewCompatible, UITextFieldDelegate {
    
    // Interfaces exposed to view controller
    private(set) lazy var tableView: UITableView = prepareTableView()
    var onSearchLocation: (String) -> Void = { _ in /* by default do nothing */ }
    
    enum Style {
        static let searchTextFieldHeight: CGFloat = 40.0
        static let searchTextFieldSideMargins: CGFloat = 15.0
    }

    private lazy var designed: Bool = implementDesign()
    private var keyboardAnimator: KeyboardAnimator?
    private var keyboardHeightConstraint: NSLayoutConstraint?
    private lazy var searchTextField: UITextField = prepareSearchTextField()
    private lazy var searchContainer: UIView = prepareSearchContainer()
    
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
        [searchContainer, searchTextField, tableView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        self.addSubview(searchContainer)
        self.addSubview(tableView)
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
            
            keyboardHeightConstraint!
        ])
    }
    
    private func prepareTableView() -> UITableView {
        let view = UITableView()
        view.insetsContentViewsToSafeArea = true
        view.clipsToBounds = true
        view.keyboardDismissMode = .onDrag
        return view
    }
    
    private func prepareSearchContainer() -> UIView {
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
