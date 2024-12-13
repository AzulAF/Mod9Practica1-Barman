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

class LoginInterface: UIViewController, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    let internetMonitor = InternetMonitor()
    
    
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
//    let actInd = UIActivityIndicatorView(style: .large)
//    // TODO: implementar cuando debe aparecer y desaparecer el activity indicator (3)
//    Funcion movida a LoginViewController
//
    
    
    // TODO: Detectar la conexión a Internet (1)
    override func viewDidLoad(){
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionStatusDidChange),
            name: .connectionStatusChanged,
            object: nil
        )
        checkInternetConnection()
    }
    
    deinit {
            NotificationCenter.default.removeObserver(self, name: .connectionStatusChanged, object: nil)
        }
    
    @objc func connectionStatusDidChange() {
            checkInternetConnection()
        }
        
        // Método para verificar la conexión actual y notificar al usuario
        func checkInternetConnection() {
            if internetMonitor.hayConexion {
                showAlert(title: "Conexión", message: "Se estableció conexión a Internet.")
            } else {
                showAlert(title: "Sin conexión", message: "No tienes acceso a Internet. Algunas funciones pueden no estar disponibles.")
            }
            //azulazulada8@gmail.com
        }
        
        // Método reutilizable para mostrar alertas
        func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    

    
    func detectaEstado () { // revisa si el usuario ya inició sesión
        // TODO: si es customLogin, hay que revisar en UserDefaults (2)
        if let customLogin = UserDefaults.standard.string(forKey: "customLogin"){
            print("Usuario loggeado con CustomLogin: \(customLogin) ")
            self.performSegue(withIdentifier: "loginOK", sender:nil)
            return
        }
        
        // si esta loggeado con AppleId
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: "userIdentifier"){ (credentialState, error) in
            switch credentialState{
                case .authorized:
                    print("Usuario loggeado con AppleID")
                    DispatchQueue.main.async{
                        self.performSegue(withIdentifier: "loginOK", sender: nil)
                    }
                case .revoked, .notFound:
                    print("Usuario no loggeado con appleID")
                default:
                    break;
            }
        }
        
        // si esta loggeado con Google
        GIDSignIn.sharedInstance.restorePreviousSignIn { usuario, error in
            guard let perfil = usuario else { return }
            print ("usuario: \(perfil.profile?.name ?? ""), correo: \(perfil.profile?.email ?? "")")
            self.performSegue(withIdentifier:"loginOK", sender:nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        detectaEstado()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // reutilizar custom login para que el usuario acceda por mi backend
        let loginVC = CustomLoginViewController()
        // agregar la lógica de ejecución del controller:
        self.addChild(loginVC)
        loginVC.view.frame = CGRect(x:0, y:45, width:self.view.bounds.width, height:self.view.bounds.width)
        // agregamos la vista de customlogin como subvista
        self.view.addSubview(loginVC.view)
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
        GIDSignIn.sharedInstance.signIn(withPresenting:self){ resultado, error in
            if error != nil {
                Utils.showMessage("ERROR: \(error?.localizedDescription)")
            }
            else {
                guard let perfil = resultado?.user else { return }
                print ("usuario: \(perfil.profile?.name), correo: \(perfil.profile?.email)")
                self.performSegue(withIdentifier: "loginOK", sender: nil)
            }
        }
    }
    
    @objc func appleBtnTouch () {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authController = ASAuthorizationController(authorizationRequests:[request])
        authController.presentationContextProvider = self
        authController.delegate = self
        authController.performRequests()
    }
}
