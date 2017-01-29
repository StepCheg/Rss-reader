//
//  SavedPostsCollectionViewController.swift
//  Test Reader
//
//  Created by Stepan Chegrenev on 18.01.17.
//  Copyright © 2017 Stepan Chegrenev. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "SavedPostsCollectionViewCell"

class SavedPostsCollectionViewController: UICollectionViewController {

    var savedPosts: [Post]?
    var appDelegate: AppDelegate!
    var context: NSManagedObjectContext!
    var postRequest: NSFetchRequest<NSFetchRequestResult>!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        savedPosts = []
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        context = appDelegate.persistentContainer.viewContext
        
        postRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        self.collectionView?.backgroundColor = UIColor.white
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        savedPosts = []
        
        postRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try context.fetch(postRequest)
            
            if results.count > 0
            {
                for result in results as! [NSManagedObject]
                {
                    let post = result as! Post
                    
                    if post.isSavedPost
                    {
                        if !(savedPosts?.contains(post))!
                        {
                            savedPosts?.append(post)
                        }
                    }
                }
            }
        }
        catch
        {
            // PROCESS ERROR
        }
        
        savedPosts?.sort(by: { $0.postsPubDate!.compare($1.postsPubDate! as Date) == .orderedDescending })
        
        self.collectionView!.reloadData()
    }
    
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return (savedPosts?.count)!
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
        
        // Configure the cell
        
        let item = self.savedPosts![indexPath.row]
        
        cell.titleLabel.text = item.postsTitle
        cell.sourceLabel.text = item.channelTitle
        cell.dateLabel.text =  cell.changeDate(pubDate: item.postsPubDate!)
        
        let array = NSKeyedUnarchiver.unarchiveObject(with: item.imageURLsFromDescription as! Data) as? [String]
        
        if array == nil || array?.count == 0
        {
            cell.newsImage.image = UIImage(named: "roundedDefaultFeed")
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: { () -> Void in
            for imageURLString in array!
            {
                if let image = self.loadImageSynchronouslyFromURLString(imageURLString)
                {
                    DispatchQueue.main.async(execute: { () -> Void in
                        cell.newsImage.image = image
                    })
                    break;
                }
            }
        })
        
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1.00).cgColor
        
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        self.performSegue(withIdentifier: "SavedPostCollectionViewCellSegue", sender: savedPosts?[indexPath.row])
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "SavedPostCollectionViewCellSegue"
        {
            let destViewController = segue.destination as! PostViewController
            let post = sender as! Post
            
            destViewController.post = post
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    
    func loadImageSynchronouslyFromURLString(_ urlString: String) -> UIImage?
    {
        if let url = URL(string: urlString)
        {
            let request = NSMutableURLRequest(url: url)
            request.timeoutInterval = 30.0
            var response: URLResponse?
            let error: NSErrorPointer? = nil
            var data: Data?
            
            do
            {
                data = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
            }
            catch let error1 as NSError
            {
                error??.pointee = error1
                data = nil
            }
            
            if (data != nil)
            {
                return UIImage(data: data!)
            }
        }
        
        return nil
    }
}
