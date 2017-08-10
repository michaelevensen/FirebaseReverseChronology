//
//  ViewController.swift
//  FirebaseReverseChronology
//
//  Created by Michael Evensen on 10/08/2017.
//  Copyright © 2017 Michael Evensen. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController {

    @IBOutlet weak var dataCollectionView: UICollectionView!
    
    //
    var ref: DatabaseReference!
    
    // Data
    var data: [String] = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.ref = Database.database().reference()
        
        // Observe
        self.ref.observe(.childAdded, with: { snapshot in
            self.data.append(snapshot.key)
            
            // Sort by Firebase keys. Note: This needs to be sorted identical to the Firebase data ordering. In this case reverse chronology.
            self.data.sort(by: {$0 > $1 })
            
            // This preserves proper index ordering based on sort.
            guard let index = self.data.index(of: snapshot.key) else {
                return
            }
            self.dataCollectionView.insertItems(at: [IndexPath(row: index, section: 0)])
        })
        
        self.ref.observe(.childRemoved, with: { snapshot in
            guard let index = self.data.index(of: snapshot.key) else {
                return
            }
            self.data.remove(at: index)
            self.dataCollectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        })
    }
    
    // MARK: - Did tap add
    @IBAction func didTapAdd(_ sender: Any) {
        let date = Date().timeIntervalSince1970
        let reversedDate = 0 - date
        
        // Construct dummy data
        let childUpdates: [String: Any] = [
            "\(self.ref.childByAutoId().key)": [
                "createdAt": date,
                ".priority": reversedDate
            ]
        ]
        
        // Update
        self.ref.updateChildValues(childUpdates) { error, ref in
            if let errorDescription = error?.localizedDescription {
                print(errorDescription)
            }
            else {
                print("Added \(ref)")
            }
        }
    }
    
    // MARK: - Did tap remove
    @IBAction func didTapRemove(_ sender: Any) {
        
        // Remove most recent
        self.ref.queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snapshot in
            
            // Note: Required to enumerate because of queryLimited()
            for child in snapshot.children {
                let child = child as! DataSnapshot
                
                // Remove
                child.ref.removeValue()
            }
        })
    }
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        
        // Unwrap text
        cell.textLabel.text = self.data[indexPath.row]
        
        return cell
        
    }
}
