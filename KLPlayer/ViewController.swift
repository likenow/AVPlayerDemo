//
//  ViewController.swift
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    public static let cellResuseIdentifier = "home_cell_id"
    
    lazy var tableView: UITableView = {
        let tableview = UITableView(frame: .zero, style: .plain)
        tableview.delegate = self
        tableview.dataSource = self
        
        return tableview
    }()
    
    let datas = ["Player","Player"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.addSubview(self.tableView)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ViewController.cellResuseIdentifier)
        self.tableView.snp.makeConstraints { (make) in
            make.width.equalTo(self.view)
            make.height.equalTo(self.view)
            make.center.equalTo(self.view)
        }
    }
    func viewController(name :String) -> UIViewController? {
        let className = "\(name)ViewController"
        let clzz = NSClassFromString(className) as? UIViewController.Type
        if let clazz = clzz {
            return clazz.init(nibName: nil, bundle: nil)
        }
        return nil
    }

}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = self.datas[indexPath.row]
        if let vc = self.viewController(name: name) {
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.cellResuseIdentifier)
        let name = self.datas[indexPath.row]
        cell?.textLabel?.text = name
        return cell!
    }
}

