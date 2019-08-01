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

class ViewController: UIViewController {

    @IBOutlet weak var noteTxt: UITextField!
    
    @IBOutlet weak var noteLbl: UILabel!
    
    @IBAction func sendBtnWasPressed(_ sender: Any) {
        
        createNote(noteTxt.text!)
        
        //let qNote = queryNotes()
        
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
            //loadNote("123")
           // updateNote("123", "updated note")
           // deleteNote("123")
            queryNotes()
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

}

