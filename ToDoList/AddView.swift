import UIKit

class AddView: UIViewController {
  
    weak var delegate: AddViewControllerDelegate?
    var itemToEdit: String?
    var editingIndexPath: IndexPath?
    var currentCategory: String?
    
    private let textField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "Add something to do"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private var selectedCategory: String = "General" {
        didSet {
            categoryButton.setTitle(selectedCategory, for: .normal)
        }
    }
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a category"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("General", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        if let itemToEdit = itemToEdit {
            textField.text = itemToEdit
            title = "Edit"
            if let category = currentCategory {
                selectedCategory = category
            }
        } else {
            title = "Add"
        }
    }
    
    private func setupUI() {
        view.addSubview(textField)
        view.addSubview(categoryLabel)
        view.addSubview(categoryButton)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            categoryLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            categoryButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            categoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            categoryButton.leadingAnchor.constraint(greaterThanOrEqualTo: categoryLabel.trailingAnchor, constant: 20),
            categoryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }
    
    @objc private func categoryButtonTapped() {
        let alertController = UIAlertController(title: "Select Category", message: nil, preferredStyle: .actionSheet)
        
        let categories = ["General", "Business", "Personal", "Shop", "Health"]
        
        for category in categories {
            let action = UIAlertAction(title: category, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.categoryButton.setTitle(category, for: .normal)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let text = textField.text, !text.isEmpty else {
            let alert = UIAlertController(title: "Alert",
                                        message: "You didn't enter any text",
                                        preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            present(alert, animated: true)
            return 
        }
        delegate?.didSaveItem(text, at: editingIndexPath, category: selectedCategory)
        navigationController?.popViewController(animated: true)
    }
}
