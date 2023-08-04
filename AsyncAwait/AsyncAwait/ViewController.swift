//
//  ViewController.swift
//  AsyncAwait
//
//  Created by Viktor Golovach on 04.08.2023.
//

import UIKit



class ViewController: UIViewController {
    
    //URL to get users
    private let url = URL(string: "https://jsonplaceholder.typicode.com/users")
    
    //TableView
    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    //MARK: - Data Source
    private var dataSource: UITableViewDiffableDataSource<Sections, User>!
    private var users = [User]()
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
        initdataSource()
        updateUsersData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //to update frame of tableView
        self.tableView.frame = self.view.bounds
    }
    
    //MARK: - Methods
    private func initTableView() {
        self.tableView.delegate = self
        self.view.addSubview(tableView)
    }
    
    //inititalize Data Source for tableView
    private func initdataSource() {
        dataSource = UITableViewDiffableDataSource(
            tableView: self.tableView,
            cellProvider: { tableView, indexPath, model -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
                    return UITableViewCell()
                }
                cell.textLabel?.text = model.name
                return cell
            })
    }
    
    //applying new data to tableView Data Source
    private func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, User>()
        snapshot.appendSections([.user])
        snapshot.appendItems(users)
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func updateUsersData() {
        Task { [weak self] in
            guard let self = self else {return}
            let result = await fetchUsers()
            if let error = result.1 {
                print(error)
            } else if let users = result.0 {
                self.users = users
                self.reloadData()
            }
        }
    }
    
    //fetching users
    private func fetchUsers() async -> ([User]?, String?) {
        guard let url = url else {
            return (nil, "Bad url")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let users = try JSONDecoder().decode([User].self, from: data)
            return (users, nil)
        }
        //All Catch casses for possible JSONDecoder errors
        catch let DecodingError.dataCorrupted(context) {
            return (nil, "\(context)")
        } catch let DecodingError.keyNotFound(key, context) {
            return (nil, "Key '\(key)' not found: \(context.debugDescription)")
        } catch let DecodingError.valueNotFound(value, context) {
            return (nil, "Value '\(value)' not found: \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context)  {
            return (nil, "Type '\(type)'  mismatch: \(context.debugDescription)")
        } catch {
            return (nil, "\(error)")
        }
    }
    
}

//MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = dataSource.itemIdentifier(for: indexPath) {
            print(user.name)
        }
    }
}

//For DiffableDataSource Sections
enum Sections: Hashable {
    case user
}

//MARK: - Model
struct User: Codable, Hashable {
    let name: String
}
