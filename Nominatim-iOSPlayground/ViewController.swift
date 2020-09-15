//
//  ViewController.swift
//  Nominatim-iOSPlayground
//
//  Created by Daisuke TONOSAKI on 2020/09/15.
//  Copyright © 2020 Daisuke TONOSAKI. All rights reserved.
//

// Nominatim Usage Policy
// https://operations.osmfoundation.org/policies/nominatim/

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    // MARK: - Outlet
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var tableView: UITableView?
    
    
    var latestSearchText = ""
    var reservedSearchText: String?
    var isSearching: Bool = false
    var nominatimObjects: [NominatimObject]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.dataSource = self
        tableView?.allowsSelection = false
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        searchBar?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchBar?.becomeFirstResponder()
    }
    
}


// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let array = nominatimObjects, array.count > 0 else {
            // Dummy content for empty.
            return 1
        }
        
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""
        
        
        guard let array = nominatimObjects, array.count > 0 else {
            // Dummy content for empty.
            cell.textLabel?.text = "No results."
            
            return cell
        }
        
        
        let item = array[indexPath.row]
        
        cell.textLabel?.text = item.displayName
        cell.detailTextLabel?.text = ""
        
        
        return cell
    }
    
}


// MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        search(searchText: "")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        search(searchText: searchBar.text ?? "")
    }
    
}


// MARK: - Search
extension ViewController {
    
    func search(searchText: String) {
        guard latestSearchText != searchText else {
            return
        }
        
        guard !isSearching else {
            reservedSearchText = searchText
            return
        }
        
        print("search [\(searchText)]")
        
        isSearching = true
        latestSearchText = searchText
        nominatimObjects = []
        
        searchNominatim(searchText: searchText)
    }
    
    func searchNominatim(searchText: String) {
        let session = URLSession.init(configuration: URLSessionConfiguration.default,
                                      delegate: nil,
                                      delegateQueue: OperationQueue.main)
        
        var url = "https://nominatim.openstreetmap.org/search?"
        url += "format=json"
        url += "&q=" + searchText.urlEncode
        url += "&limit=" + "50"
        url += "&accept-language=" + (NSLocale.preferredLanguages.first ?? "en-US")
        // url += "&addressdetails=1"
        // url += "&email=" + searchText
        
        print("url[\(url)]")
        
        let req = URLRequest(url: URL(string: url)!,
                             cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                             timeoutInterval: 30)
        
        let task = session.dataTask(with: req) { (data, response, error) in
            
            guard error == nil, let data = data else {
                self.searchComplete(searchText: searchText, nominatimObjects: nil)
                return
            }
            
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                guard let jsonArray = json as? [[String: AnyObject]] else {
                    self.searchComplete(searchText: searchText, nominatimObjects: nil)
                    return
                }
                
                
                var nominatimObjects: [NominatimObject] = []
                for jsonElement in jsonArray {
                    
                    guard let latStr = jsonElement["lat"] as? String,
                        let lat = Double(latStr) else {
                            continue
                    }
                    
                    guard let lonStr = jsonElement["lon"] as? String,
                        let lon = Double(lonStr) else {
                            continue
                    }
                    
                    
                    let nominatim = NominatimObject(displayName: jsonElement["display_name"] as? String ?? "",
                                                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                                    importance: jsonElement["importance"] as? Double ?? 0,
                                                    type: jsonElement["type"] as? String ?? "")
                    nominatimObjects.append(nominatim)
                }
                
                self.searchComplete(searchText: searchText, nominatimObjects: nominatimObjects)
            } catch {
                self.searchComplete(searchText: searchText, nominatimObjects: nil)
            }
        }
        
        task.resume()
    }
    
    
    func searchComplete(searchText: String, nominatimObjects: [NominatimObject]?) {
        print("searchComplete [\(searchText)]")
        
        var nominatimObjects = nominatimObjects
        
        nominatimObjects = nominatimObjects?.filter {
            $0.type == "administrative"
        }
        
        
        // Remove duplicates
        var nominatimObjects2: [NominatimObject] = []
        for nominatim in nominatimObjects ?? [] {
            guard let index = nominatimObjects2.firstIndex(of: nominatim) else {
                nominatimObjects2.append(nominatim)
                
                continue
            }
            
            let nominatim2 = nominatimObjects2[index]
            if nominatim.importance > nominatim2.importance {
                nominatimObjects2[index] = nominatim
            }
        }
        
        
        nominatimObjects2.sort {
            $0.importance > $1.importance
        }
        
        self.nominatimObjects = nominatimObjects2
        
        
        tableView?.reloadData()
        isSearching = false
        
        guard let searchTextNext = reservedSearchText else {
            return
        }
        
        reservedSearchText = nil
        search(searchText: searchTextNext)
    }
    
}
