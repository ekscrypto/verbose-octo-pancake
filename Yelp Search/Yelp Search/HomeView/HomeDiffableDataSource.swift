//
//  HomeDiffableDataSource.swift
//  Yelp Search
//
//  Created by Dave Poirier on 2021-12-23.
//

import UIKit

class HomeDiffableDataSource: UITableViewDiffableDataSource<Int, YelpBusiness>, UITableViewDelegate {
    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<Int, YelpBusiness>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.height * 0.6
    }
}
