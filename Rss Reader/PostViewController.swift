//
//  PostViewController.swift
//  Test Reader
//
//  Created by Stepan Chegrenev on 27.11.16.
//  Copyright © 2016 Stepan Chegrenev. All rights reserved.
//

import UIKit
import CoreData
import Kanna

class PostViewController: UIViewController {
    
    var post: Post?
    var appDelegate: AppDelegate!
    var context: NSManagedObjectContext!
    var postRequest: NSFetchRequest<NSFetchRequestResult>!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet var myScrollView: UIScrollView!

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        context = appDelegate.persistentContainer.viewContext
        
        postRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        self.navigationItem.title = post?.postsTitle
        
        titleLabel.text = post?.postsTitle
        contentLabel.text = post?.postsText
        
        let array = NSKeyedUnarchiver.unarchiveObject(with: post?.imageURLsFromDescription as! Data) as? [String]
        
        if array == nil || array?.count == 0
        {
            imageView.image = UIImage(named: "roundedDefaultFeed")
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: { () -> Void in
            for imageURLString in array!
            {
                if let image = self.loadImageSynchronouslyFromURLString(imageURLString)
                {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.imageView.image = image
                    })
                    break;
                }
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
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
    
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func openLinkAction(_ sender: UIBarButtonItem)
    {
        let alertController = UIAlertController(title: "Choise action", message: nil, preferredStyle: .actionSheet)
        
        do
        {
            let results = try context.fetch(postRequest)
            
            if results.count > 0
            {
                for result in results as! [NSManagedObject]
                {
                    let obj = result as? Post
                    
                    if post == obj
                    {
                        if (self.post?.isSavedPost)!
                        {
                            let savePostButton = UIAlertAction(title: "Unsave Post", style: .default) { action in
                                self.post?.isSavedPost = false
                                obj?.isSavedPost = false
                            }
                            
                            do
                            {
                                try context.save()
                                print("SAVED")
                            }
                            catch
                            {
                                //PROCESS ERROR
                            }
                            
                            alertController.addAction(savePostButton)
                        }
                        else
                        {
                            let savePostButton = UIAlertAction(title: "Save Post", style: .default) { action in
                                self.post?.isSavedPost = true
                                obj?.isSavedPost = true
                            }
                            
                            do
                            {
                                try context.save()
                                print("SAVED")
                            }
                            catch
                            {
                                //PROCESS ERROR
                            }
                            
                            alertController.addAction(savePostButton)
                        }
                    }
                }
            }
        }
        catch
        {
            // PROCESS ERROR
        }
        
        let openInSafariButton = UIAlertAction(title: "Open in Safari", style: .default) { action in
            UIApplication.shared.open(NSURL(string: (self.post?.postsLink)!) as! URL, options: [:], completionHandler: nil)
        }
        
        alertController.addAction(openInSafariButton)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelButton)
        
        present(alertController, animated: true, completion: nil)
    }
}
