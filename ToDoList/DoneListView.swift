//
//  DoneListView.swift
//  toDoProgramatic2
//
//  Created by Cüneyt Elbastı on 14.01.2025.
//

import UIKit

class DoneListView: UIViewController {
    private var completedItems: [[String: Any]] = []
    private var tableView: UITableView!
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "You didn't complete any tasks yet!"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        label.backgroundColor = .white
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Done List"
        view.backgroundColor = .white
        setupTableView()
   
        completedItems = UserDefaults.standard.array(forKey: "completedItems") as? [[String: Any]] ?? []
        checkEmptyState()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .white
        
   
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        emptyLabel.frame = view.bounds
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func checkEmptyState() {
        emptyLabel.isHidden = !completedItems.isEmpty
        tableView.isHidden = completedItems.isEmpty
    }
}

extension DoneListView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        
        let item = completedItems[indexPath.row]
        let text = item["text"] as? String ?? ""
        let category = item["category"] as? String ?? "Genel"
        let date = item["date"] as? Date ?? Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: date)
        
        cell.textLabel?.text = text
        cell.detailTextLabel?.text = "Category: \(category) • Finished: \(dateString)"
        
        return cell
    }
}
