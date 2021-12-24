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
    
    private lazy var tableDiffableDataSource = HomeDiffableDataSource(tableView: homeView.tableView) { [weak self] tableView, indexPath, yelpBusiness in
        let cell = tableView.dequeueReusableCell(withIdentifier: BusinessListingCell.reuseIdentifier, for: indexPath)
        (cell as? BusinessListingCell)?.business = yelpBusiness
        self?.loadMoreIfNeeded(row: indexPath.row)
        return cell
    }
    
    override func loadView() {
        self.view = homeView
        attachDataSourceToTableView()
        attachSearchTextFieldToViewModel()
    }
    
    private func loadMoreIfNeeded(row: Int) {
        if row > viewModel.businesses.count - 5 {
            viewModel.loadMore()
        }
    }
    
    private func attachDataSourceToTableView() {
        homeView.tableView.register(BusinessListingCell.self, forCellReuseIdentifier: BusinessListingCell.reuseIdentifier)
        _ = tableDiffableDataSource
        viewModel.onBusinesses = { [weak self] businesses in self?.prepareSnapshot(businesses) }
        viewModel.onConnectivityError = { [weak self] connectivityError in self?.homeView.showConnectivityError = connectivityError }
        viewModel.onPendingQuery = { [weak self] pendingQuery in self?.homeView.showActivity = pendingQuery }
    }
    
    private func attachSearchTextFieldToViewModel() {
        homeView.onSearchLocation = { [weak self] searchLocation in
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

