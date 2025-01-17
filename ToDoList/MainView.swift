import UIKit

class MainView: UIViewController {
    var categorizedItems: [String: [String]] = [:] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let encoded = try? JSONEncoder().encode(self.categorizedItems) {
                    UserDefaults.standard.set(encoded, forKey: "todoItems")
                    UserDefaults.standard.synchronize()
                }
                self.checkEmptyState()
            }
        }
    }
    var categories: [String] = []
    
    var tableView: UITableView!
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "You didn't add anything yet."
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        return label
    }()
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredItems: [String: [String]] = [:]
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    private var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupTableView()
        setupToolbarButtons()
        
        if let savedData = UserDefaults.standard.data(forKey: "todoItems"),
           let savedItems = try? JSONDecoder().decode([String: [String]].self, from: savedData) {
            categorizedItems = savedItems
            categories = Array(savedItems.keys)
        }
        
        view.addSubview(emptyLabel)
        emptyLabel.frame = view.bounds
        checkEmptyState()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func checkEmptyState() {
        let isEmpty = categories.isEmpty || categorizedItems.values.flatMap { $0 }.isEmpty
        
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty {
            categories = []
            categorizedItems = [:]
        }
        
        tableView.reloadData()
    }
    
    func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
    }
    
    func setupToolbarButtons() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
        
        let listButton = UIBarButtonItem(
            barButtonSystemItem: .bookmarks,
            target: self,
            action: #selector(listButtonTapped)
            )
        
        navigationItem.leftBarButtonItem = listButton
    }
    
    
    @objc func listButtonTapped() {
        let doneVc = DoneListView()
        navigationController?.pushViewController(doneVc, animated: true)
    }
    
    @objc func addButtonTapped() {
        let addVC = AddView()
        addVC.delegate = self
        navigationController?.pushViewController(addVC, animated: true)
    }
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredItems = [:]
        
        for (category, items) in categorizedItems {
            let filteredCategoryItems = items.filter { item in
                return item.lowercased().contains(searchText.lowercased())
            }
            if !filteredCategoryItems.isEmpty {
                filteredItems[category] = filteredCategoryItems
            }
        }
        
        tableView.reloadData()
    }
}


extension MainView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering {
            return filteredItems.keys.count
        }
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            let category = Array(filteredItems.keys)[section]
            return filteredItems[category]?.count ?? 0
        }
        let category = categories[section]
        return categorizedItems[category]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering {
            return Array(filteredItems.keys)[section]
        }
        return categories[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let category: String
        let items: [String]
        
        if isFiltering {
            category = Array(filteredItems.keys)[indexPath.section]
            items = filteredItems[category] ?? []
        } else {
            category = categories[indexPath.section]
            items = categorizedItems[category] ?? []
        }
        
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
 
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            let category = self.categories[indexPath.section]
            self.categorizedItems[category]?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completion(true)
        }
        
        let doneAction = UIContextualAction(style: .destructive, title: "Done") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            if let completedItem = self.categorizedItems[self.categories[indexPath.section]]?[indexPath.row] {
                var completedItems = UserDefaults.standard.array(forKey: "completedItems") as? [[String: Any]] ?? []
                let completedItemDict: [String: Any] = [
                    "text": completedItem,
                    "category": self.categories[indexPath.section],
                    "date": Date()
                ]
                completedItems.append(completedItemDict)
                UserDefaults.standard.set(completedItems, forKey: "completedItems")
                
                self.categorizedItems[self.categories[indexPath.section]]?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            completion(true)
        }
        doneAction.backgroundColor = .systemGreen
      
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            let addVC = AddView()
            addVC.delegate = self
            
            let category = self.categories[indexPath.section]
            if let itemToEdit = self.categorizedItems[category]?[indexPath.row] {
                addVC.itemToEdit = itemToEdit
                addVC.editingIndexPath = indexPath
                addVC.currentCategory = category
            }
            
            self.navigationController?.pushViewController(addVC, animated: true)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
        return configuration
    }
}


extension MainView: AddViewControllerDelegate {
    func didSaveItem(_ item: String, at indexPath: IndexPath?, category: String) {
        tableView.beginUpdates()
        
        if let indexPath = indexPath {
            let oldCategory = categories[indexPath.section]
            
            if oldCategory == category {
                categorizedItems[oldCategory]?[indexPath.row] = item
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                categorizedItems[oldCategory]?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                if categorizedItems[oldCategory]?.isEmpty == true {
                    categorizedItems.removeValue(forKey: oldCategory)
                    if let oldCategoryIndex = categories.firstIndex(of: oldCategory) {
                        categories.remove(at: oldCategoryIndex)
                        tableView.deleteSections(IndexSet(integer: oldCategoryIndex), with: .automatic)
                    }
                }
                
                if categorizedItems[category] == nil {
                    categorizedItems[category] = []
                    categories.append(category)
                    tableView.insertSections(IndexSet(integer: categories.count - 1), with: .automatic)
                }
                
                categorizedItems[category]?.append(item)
                let newIndexPath = IndexPath(row: (categorizedItems[category]?.count ?? 1) - 1,
                                           section: categories.firstIndex(of: category) ?? 0)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        } else {
            if categorizedItems[category] == nil {
                categorizedItems[category] = []
                categories.append(category)
                let newSectionIndex = categories.count - 1
                tableView.insertSections(IndexSet(integer: newSectionIndex), with: .automatic)
            }
            
            categorizedItems[category]?.append(item)
            let newIndexPath = IndexPath(row: (categorizedItems[category]?.count ?? 1) - 1, 
                                       section: categories.firstIndex(of: category) ?? 0)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
        
        tableView.endUpdates()
        checkEmptyState()
    }
}


protocol AddViewControllerDelegate: AnyObject {
    func didSaveItem(_ item: String, at indexPath: IndexPath?, category: String)
}


extension MainView: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}


