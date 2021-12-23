//
//  ViewController.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-21.
//

import UIKit

final class HomeViewController: UIViewController {

    private let viewModel: HomeViewModelCompatible = HomeViewModel()
    private let homeView: HomeViewCompatible = HomeView()
    
    private lazy var tableDiffableDataSource = UITableViewDiffableDataSource<Int, YelpBusiness>(tableView: homeView.tableView) { tableView, indexPath, yelpBusiness in
        
        let cell = tableView.dequeueReusableCell(withIdentifier: BusinessListingCell.reuseIdentifier, for: indexPath)
        (cell as? BusinessListingCell)?.business = yelpBusiness
        return cell
    }
    
    override func loadView() {
        self.view = homeView
        attachDataSourceToTableView()
        attachSearchTextFieldToViewModel()
    }
    
    private func attachDataSourceToTableView() {
        homeView.tableView.register(BusinessListingCell.self, forCellReuseIdentifier: BusinessListingCell.reuseIdentifier)
        _ = tableDiffableDataSource
        viewModel.onBusinesses = { [weak self] businesses in self?.prepareSnapshot(businesses) }
    }
    
    private func attachSearchTextFieldToViewModel() {
        homeView.onSearchLocation = { [weak self] searchLocation in
            print("\(Self.self).\(#line) Search location: \(searchLocation)")
            self?.viewModel.searchLocation = searchLocation
        }
    }
    
    private func prepareSnapshot(_ businesses: [YelpBusiness]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, YelpBusiness>()
        snapshot.appendSections([0])
        snapshot.appendItems(businesses, toSection: 0)
        tableDiffableDataSource.apply(snapshot)
    }
}

