//
//  ViewController.swift
//  AWSNotes
//
//  Created by McKinney family  on 7/31/19.
//  Copyright © 2019 FasTek Technologies. All rights reserved.
//

import UIKit
import AWSAuthUI
import AWSAuthCore
import AWSCore
import AWSDynamoDB
import AWSS3
import AWSCognito

class ViewController: UIViewController {

    
    
    @IBOutlet weak var noteTxt: UITextField!
    
    @IBOutlet weak var noteLbl: UILabel!
    
    @IBOutlet weak var img: UIImageView!
    
    @IBAction func sendBtnWasPressed(_ sender: Any) {
        
        createNote(noteTxt.text!)
        endTouching()
        noteLbl.text = "\(queryNotes())"
        
    }
    
    @IBAction func logoutBtnWasPressed(_ sender: Any){
        AWSSignInManager.sharedInstance().logout { (value, error) in
            self.checkForLogin()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkForLogin()
    }
    
   
    
    func endTouching(){
        self.view.endEditing(true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func checkForLogin(){
        if !AWSSignInManager.sharedInstance().isLoggedIn{
            AWSAuthUIViewController.presentViewController(with: self.navigationController!, configuration: nil) { (provider, error) in
                if error == nil {
                    print("success")
                }
                else {
                    print(error?.localizedDescription ?? "no value")
                }
            }
        }
        else {
            //createNote("100")
            //createNote("125")
            //createNote("101")
            //loadNote(noteLbl.text!)
           // updateNote("123", "updated note")
           // deleteNote("123")
            //queryNotes()
            downloadData()
            uploadFile()
        }
    }

    
    func createNote(_ noteID: String){
        guard let note = Note() else {return}
        
        note._userId = AWSIdentityManager.default().identityId
        note._noteId = noteID
        note._content = "Text for my note"
        note._creationDate = Date().timeIntervalSince1970 as NSNumber
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        note._title = "My note on \(df.string(from: Date()))"
        saveNote(note)
        
    }
    
    func saveNote(_ note: Note){
        let dbObjMapper = AWSDynamoDBObjectMapper.default()
        dbObjMapper.save(note) { (error) in
            print(error?.localizedDescription ?? "no error")
        }

    }
    
    func loadNote(_ noteID: String){
        let dbObjectMapper = AWSDynamoDBObjectMapper.default()
        if let hashKey = AWSIdentityManager.default().identityId{
            dbObjectMapper.load(Note.self, hashKey: hashKey, rangeKey: noteID) { (model, error) in
                if let note = model as? Note {
                    print(note._content ?? "no content")
                }
            }
        }
    }
    
    func updateNote(_ noteID: String, _ content: String){
        let dbObjectMapper = AWSDynamoDBObjectMapper.default()
        if let hashKey = AWSIdentityManager.default().identityId{
            dbObjectMapper.load(Note.self, hashKey: hashKey, rangeKey: noteID) { (model, error) in
                if let note = model as? Note {
                    note._content = content
                    self.saveNote(note)
                    print(note._content ?? "no content")
                }
            }
        }
    }
    
    func deleteNote(_ noteID: String){
        if let note = Note(){
            note._userId = AWSIdentityManager.default().identityId
            let dbObjectMapper = AWSDynamoDBObjectMapper.default()
            dbObjectMapper.remove(note) { (error) in
                print(error?.localizedDescription ?? "no error")
            }
        }
    }
    
    func queryNotes(){
        let qExp = AWSDynamoDBQueryExpression()
        qExp.keyConditionExpression = "#uID = :userId" //add "#uID = :userID and #noteId > :someId"
        qExp.expressionAttributeNames = ["#uId": "userId"] //add ["#uId: "userId", "#noteId":"noteId"]
        qExp.expressionAttributeValues = [":userId": AWSIdentityManager.default().identityId!] //at the end of identityId ":someId":"100"]
        
        let dbObjectMapper  = AWSDynamoDBObjectMapper.default()
        dbObjectMapper.query(Note.self, expression: qExp) { (output, error) in
            if let notes = output?.items as? [Note]{
                notes.forEach({ (note) in
                    self.noteLbl.text = note._content
                    print(note._content ?? "no content")
                    print(note._content ?? "no id")
                })
                
            }
        }
    }
    
    
    func downloadData() {
        var completionHandler : AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { (task, URL, data, error) in
            DispatchQueue.main.async {
                let iv = UIImageView.init(frame: self.view.bounds)
                iv.contentMode = .scaleAspectFit
                iv.image = UIImage.init(data: data!)
                self.view.addSubview(iv)
            }
        }
        
        let tUtil = AWSS3TransferUtility.default()
        tUtil.downloadData(forKey: "public/pic.jpg", expression: nil, completionHandler: completionHandler)
        
    }
    
    func uploadFile() {
        var completionHandler : AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task,error) in
            print (task.response?.statusCode ?? "0")
            print (error?.localizedDescription ?? "no error")
        }
        
        let exp = AWSS3TransferUtilityUploadExpression()
        exp.progressBlock = {(task,progress) in
            DispatchQueue.main.async {
                // update UI
                print(progress.fractionCompleted)
            }
        }
        
        let data = #imageLiteral(resourceName: "boston terrier").jpegData(compressionQuality: 0.5)
        
        let tUtil = AWSS3TransferUtility.default()
        tUtil.uploadData(data!, key: "public/pic.jpg", contentType: "image/jpg", expression: exp, completionHandler: completionHandler)
    }
    

}

