//
//  LoginInterface.swift
//  Barman
//
//  Created by Ángel González on 07/12/24.
//

import Foundation
import UIKit
import AuthenticationServices
import GoogleSignIn

class LoginInterface: UIViewController, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate, CustomLoginViewControllerDelegate {
    let internetMonitor = InternetMonitor()
    
    func customLoginViewController(_ me: CustomLoginViewController, performLogin: Bool) {
        if performLogin {
            let userDefaultToUse3 = UserDefaults.standard
            userDefaultToUse3.set(true, forKey: "customLogin")
            userDefaultToUse3.synchronize()
            
            // Solo LoginInterface llama al segue
            //DispatchQueue.main.async {
                self.performSegue(withIdentifier: "loginOK", sender: self)
            //}
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginOK" {
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
//    let actInd = UIActivityIndicatorView(style: .large)
//    // TODO: implementar cuando debe aparecer y desaparecer el activity indicator (3)
//    Funcion movida a LoginViewControlller
//
    
    let activityInd2 = UIActivityIndicatorView(style: .large)
    func showActivityIndicator(){
        activityInd2.center = self.view.center
        self.view.addSubview(activityInd2)
        activityInd2.startAnimating()
    }
    
    func hideActivityIndicator(){
        activityInd2.stopAnimating()
        activityInd2.removeFromSuperview()
    }
    
    func InternetStatus() -> Bool {
        print("LLega a aca. Si hay internet, true")
        if NetworkReachability.shared.isConnected{
            print(NetworkReachability.shared.isConnected)}
        return NetworkReachability.shared.isConnected
    }
    
    // TODO: Detectar la conexión a Internet (1)
    override func viewDidLoad(){
        super.viewDidLoad()
        checkInternetConnection()
    }
    
        
    // Método para verificar la conexión actual y notificar al usuario
    //NO USAR PARA MOSTRAR SOLO SI ESTA CONECTADO, NO PERMITE QUE SE INGRESE
    func checkInternetConnection() {
        if !InternetStatus() {
        
            showAlert(title: "Sin conexión", message: "No tienes acceso a Internet. Algunas funciones pueden no estar disponibles.")
        }
        //
    }
        
    // Método reutilizable para mostrar alertas
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    

    
    func detectaEstado () { // revisa si el usuario ya inició sesión
        showActivityIndicator()
        // TODO: si es customLogin, hay que revisar en UserDefaults (2)
        if let customLogin = UserDefaults.standard.string(forKey: "customLogin"){
            print("Usuario loggeado con CustomLogin")
            self.performSegue(withIdentifier: "loginOK", sender:nil)
            hideActivityIndicator()
        }
        
        // si esta loggeado con AppleId
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: "userIdentifier"){ (estadocred, error) in
            switch estadocred{
                case .authorized:
                    print("Usuario loggeado con AppleID")
                    DispatchQueue.main.async{self.performSegue(withIdentifier: "loginOK", sender: nil)}
                
                default:
                    print("Usuario no loggeado con appleID")
                    DispatchQueue.main.async {
                        self.hideActivityIndicator()
                    }
                    break

            }
        }
        
        // si esta loggeado con Google
        GIDSignIn.sharedInstance.restorePreviousSignIn { (usuario, error) in
            DispatchQueue.main.async {
                guard let perfil = usuario else {
                    self.hideActivityIndicator()
                    return
                }
                print("Usuario: \(perfil.profile?.name ?? ""), Correo: \(perfil.profile?.email ?? "")")
                self.performSegue(withIdentifier: "loginOK", sender: nil)
                self.hideActivityIndicator()
            }
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkInternetConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // reutilizar custom login para que el usuario acceda por mi backend
        let loginVC = CustomLoginViewController()
        loginVC.delegate = self
        // agregar la lógica de ejecución del controller:
        self.addChild(loginVC)
        loginVC.view.frame = CGRect(x:0, y:45, width:self.view.bounds.width, height:self.view.bounds.width)
        // agregamos la vista de customlogin como subvista
        self.view.addSubview(loginVC.view)
        loginVC.didMove(toParent: self)
        // agregar boton para login con appleID
        let appleIDBtn = ASAuthorizationAppleIDButton()
        self.view.addSubview(appleIDBtn)
        appleIDBtn.center = self.view.center
        appleIDBtn.frame.origin.y = loginVC.view.frame.maxY + 10
        appleIDBtn.addTarget(self, action:#selector(appleBtnTouch), for:.touchUpInside)
        let googleBtn = GIDSignInButton(frame:CGRect(x:0, y:appleIDBtn.frame.maxY + 10, width: appleIDBtn.frame.width, height:appleIDBtn.frame.height) )
        googleBtn.center.x = self.view.center.x
        self.view.addSubview(googleBtn)
        googleBtn.addTarget(self, action:#selector(googleBtnTouch), for:.touchUpInside)
    }
    
    @objc func googleBtnTouch () {
        checkInternetConnection()
        showActivityIndicator()
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { resultado, error in
                if let error = error {
                    self.hideActivityIndicator()
                    Utils.showMessage("ERROR: \(error.localizedDescription)")
                } else {
                    guard let perfil = resultado?.user else {
                        self.hideActivityIndicator()
                        return
                    }
                    print("Usuario: \(perfil.profile?.name ?? ""), Correo: \(perfil.profile?.email ?? "")")
                    self.performSegue(withIdentifier: "loginOK", sender: nil)
                    self.hideActivityIndicator()
                }
            
        }

    }
    
    @objc func appleBtnTouch () {
        checkInternetConnection()
        showActivityIndicator()
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authController = ASAuthorizationController(authorizationRequests:[request])
        authController.presentationContextProvider = self
        authController.delegate = self
        authController.performRequests()
    }
}
