//
//  HomeViewController.swift
//  FirebaseDo
//
//  Created by Doron Katz on 7/3/17.
//  Copyright © 2017 Doron Katz. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseStorageUI
import FirebasePhoneAuthUI
import ASProgressHud

class HomeViewController: UIViewController, FUIAuthDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var myImageView: UIImageView!
    let picker = UIImagePickerController()
    
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authUI: FUIAuth? //only set internally but get externally
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.auth = Auth.auth()
        self.authUI = FUIAuth.defaultAuthUI()
        self.authUI?.delegate = self
        self.authUI?.providers = [FUIPhoneAuth(authUI: self.authUI!),]
        self.authStateListenerHandle = self.auth?.addStateDidChangeListener { (auth, user) in
            guard user != nil else {
                self.loginAction(sender: self)
                return
            }
        }
        
        self.picker.delegate = self
        self.refreshProfileImage()
        
    }
    
    func refreshProfileImage(){
        if let user = Auth.auth().currentUser{
            let store = Storage.storage()
            let storeRef = store.reference().child("images/\(user.uid)/profile_photo.jpg")
            
            storeRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("error: \(error.localizedDescription)")
                } else {
                    // Data for "images/island.jpg" is returned
                    let image = UIImage(data: data!)
                    self.myImageView.image = image
                }
            }
            
            
        }else{
            print("You should be logged in")
            self.loginAction(sender: self)
            return
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    @IBAction func cameraAction(_ sender: Any) {
        self.picker.allowsEditing = false
        self.picker.sourceType = UIImagePickerControllerSourceType.camera
        self.picker.cameraCaptureMode = .photo
        self.picker.modalPresentationStyle = .fullScreen
        self.present(picker,animated: true,completion: nil)
    }
    
    @IBAction func libraryAction(_ sender: Any) {
        self.picker.allowsEditing = false
        self.picker.sourceType = .photoLibrary
        self.picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        self.present(picker, animated: true, completion: {
            print("handle saving")
        })
    }


}

//MARK: UIImagePickerView delegate methods
extension HomeViewController{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)

        let profileImageFromPicker = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let imageData: Data = UIImageJPEGRepresentation(profileImageFromPicker, 0.5)!
        
        let store = Storage.storage()
        let user = Auth.auth().currentUser
        if let user = user{
            let storeRef = store.reference().child("images/\(user.uid)/profile_photo.jpg")
            ASProgressHud.showHUDAddedTo(self.view, animated: true, type: .default)
            let _ = storeRef.putData(imageData, metadata: metadata) { (metadata, error) in
                ASProgressHud.hideHUDForView(self.view, animated: true)
                guard let _ = metadata else {
                    print("error occured: \(error.debugDescription)")
                    return
                }


                self.myImageView.image = profileImageFromPicker
            }
            
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

///MARK: Login Extensions
extension HomeViewController{
    @IBAction func loginAction(sender: AnyObject) {
        // Present the default login view controller provided by authUI
        let authViewController = authUI?.authViewController();
        self.present(authViewController!, animated: true, completion:{
            self.refreshProfileImage()
            
        })
    }
    
    
    // Implement the required protocol method for FIRAuthUIDelegate
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        guard let authError = error else { return }
        
        let errorCode = UInt((authError as NSError).code)
        
        switch errorCode {
        case FUIAuthErrorCode.userCancelledSignIn.rawValue:
            print("User cancelled sign-in");
            break
        default:
            let detailedError = (authError as NSError).userInfo[NSUnderlyingErrorKey] ?? authError
            print("Login error: \((detailedError as! NSError).localizedDescription)");
        }
    }
    
}





