//
//  NewPostsCollectionViewController.swift
//  Test Reader
//
//  Created by Stepan Chegrenev on 01.11.16.
//  Copyright © 2016 Stepan Chegrenev. All rights reserved.
//

//    http://feeds.feedburner.com/appcoda
//    https://lenta.ru/rss

import UIKit
import CoreData
import Kanna

private let reuseIdentifier = "NewPostsCollectionViewCell"

class NewPostsCollectionViewController: UICollectionViewController, FeedParserDelegate {
    
    var feedParser: FeedParser?
    var newPosts: [Post]?
    var updatedPosts: [Post]?
    var allPosts: [Post]?
    var channels: [String]?
    var channelURL: String?
    var channelTitle: String?
    var refreshButtonIsTouch = false
    var appDelegate: AppDelegate!
    var context: NSManagedObjectContext!
    var postRequest: NSFetchRequest<NSFetchRequestResult>!

    
    @IBAction func AddFeedButtonAction(_ sender: UIBarButtonItem)
    {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Add New Feed", message: nil, preferredStyle: .alert)

        alertController.addTextField { (_ textFielder: UITextField) in
            
            textFielder.placeholder = "Enter Feed Adress"
            textField = textFielder
        }

        let addButton = UIAlertAction(title: "Add", style: .default) { Alert in
            
            if (textField?.text != "")
            {
                self.feedParser = FeedParser(feedURL: (textField?.text!)!)
                self.feedParser?.delegate = self
                self.feedParser?.parse()
            }
        }
        
        alertController.addAction(addButton)
        
        let cancelButton = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelButton)

        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func refreshPostsAction(_ sender: UIBarButtonItem)
    {
        for channel in channels!
        {
            self.feedParser = FeedParser(feedURL: channel)
            self.feedParser?.delegate = self
            self.feedParser?.parse()
        }
        
        refreshButtonIsTouch = true
    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        channels = []
        updatedPosts = []
        newPosts = []
        allPosts = []

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
        
        let oldCountOfPosts = newPosts?.count
        
        postRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try context.fetch(postRequest)
            
            if results.count > 0
            {
                for result in results as! [NSManagedObject]
                {
                    let post = result as! Post
                    
                    if !(allPosts?.contains(post))!
                    {
                        allPosts?.append(post)
                    }
                    
                    if !(newPosts?.contains(post))!
                    {
                        if post.isNewPost
                        {
                            newPosts?.append(post)
                        }
                    }
                    
                    if !(channels?.contains(post.channelSource!))!
                    {
                        channels?.append(post.channelSource!)
                    }
                }
            }
        }
        catch
        {
            // PROCESS ERROR
        }
        
        newPosts?.sort(by: { $0.postsPubDate!.compare($1.postsPubDate! as Date) == .orderedDescending })
        
        if (newPosts?.count)! > oldCountOfPosts!
        {
            self.collectionView!.reloadData()
        }
        
        if (newPosts?.count)! > 0
        {
            self.tabBarController?.tabBar.items?[0].badgeValue = "\((newPosts?.count)!)"
        }
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
        return (newPosts?.count)!
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
    
        // Configure the cell
        
        let item = self.newPosts![indexPath.row]

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
    

    func feedParser(_ parser: FeedParser, didParseChannel channel: FeedChannel)
    {
        channelURL = channel.channelURL
        channelTitle = channel.channelTitle

        if !((channels?.contains(channel.channelURL!))!)
        {
            channels?.append(channel.channelURL!)
        }
    }
    

    func feedParser(_ parser: FeedParser, didParseItem item: FeedItem)
    {
        var a = false
        
        for object in allPosts!
        {
            if object.postsLink == item.feedLink
            {
                a = true
            }
        }
        
        if !a
        {
            let newPost = Post(context: context)
            
            newPost.channelTitle = channelTitle
            newPost.channelSource = channelURL
            newPost.isNewPost = true
            newPost.isSavedPost = false
            newPost.postsLink = item.feedLink
            newPost.postsPubDate = item.feedPubDate as NSDate?
            newPost.postsText = ""
            newPost.postsTitle = item.feedTitle
            
            let html = item.feedContent!
            
            if let doc = HTML(html: html, encoding: .utf8)
            {
                for link in doc.css("p")
                {
                    if (newPost.postsText! == "")
                    {
                        newPost.postsText! = link.text!
                    }
                    else
                    {
                        newPost.postsText = newPost.postsText! + "\n\n" + link.text!
                    }
                }
            }
            
            if item.imageURLsFromDescription != nil
            {
                newPost.imageURLsFromDescription = NSKeyedArchiver.archivedData(withRootObject: item.imageURLsFromDescription!) as NSData?
            }
        
            do
            {
                try context.save()
            }
            catch
            {
                //PROCESS ERROR
            }
            
            updatedPosts?.append(newPost)
        }
    }
    

    func feedParser(_ parser: FeedParser, successfullyParsedURL url: String)
    {
        newPosts = newPosts! + updatedPosts!
        allPosts = allPosts! + updatedPosts!
        
        updatedPosts?.removeAll()
        
        newPosts?.sort(by: { $0.postsPubDate!.compare($1.postsPubDate! as Date) == .orderedDescending })

        self.collectionView!.reloadData()
        refreshButtonIsTouch = false
        channelURL = nil
        channelTitle = nil
        
        if (newPosts?.count)! > 0
        {
            self.tabBarController?.tabBar.items?[0].badgeValue = "\((newPosts?.count)!)"
        }
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
    
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        do
        {
            let results = try context.fetch(postRequest)
            
            if results.count > 0
            {
                for result in results as! [NSManagedObject]
                {
                    let post = result as? Post
                    
                    if post?.postsLink == newPosts?[indexPath.row].postsLink
                    {
                        post?.isNewPost = false
                        
                        do
                        {
                            try context.save()
                            self.performSegue(withIdentifier: "NewPostCollectionViewCellSegue", sender: post)
                        }
                        catch
                        {
                            //PROCESS ERROR
                        }
                    }
                }
            }
        }
        catch
        {
            // PROCESS ERROR
        }

        newPosts?.remove(at: indexPath.row)
        self.collectionView?.reloadData()
        
        if (newPosts?.count)! > 0
        {
            self.tabBarController?.tabBar.items?[0].badgeValue = "\((newPosts?.count)!)"
        }
        else
        {
            self.tabBarController?.tabBar.items?[0].badgeValue = nil
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "NewPostCollectionViewCellSegue"
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
}
