//
//  CustomLoginViewController.swift
//  Loginzes
//
//  Created by Angel Gonzalez Torres on 22/11/23.
//

import UIKit

protocol CustomLoginViewControllerDelegate {
    func customLoginViewController(_ me: CustomLoginViewController, performLogin: Bool)
}

class CustomLoginViewController: UIViewController, UITextFieldDelegate {

    let label:UILabel = UILabel()
    let accountField:UITextField = UITextField()
    let passwordField:UITextField = UITextField()
    let loginButton:UIButton = UIButton()
    
    // TODO: implementar cuando debe aparecer y desaparecer el activity indicator (3) v
    var delegate: CustomLoginViewControllerDelegate?
    let activityInd = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .cyan
        label.text = "Ingresa los siguientes datos:"
        label.font = UIFont(name: "SegoeUI-Semibold", size: 16)
        label.textAlignment = .center
        self.view.addSubview(label);
        accountField.placeholder = "Correo registrado:"
        accountField.setLeftPaddingPoints(10)
        accountField.customize(false)
        self.view.addSubview(accountField)
        accountField.keyboardType = .emailAddress
        accountField.autocapitalizationType = .none
        accountField.autocorrectionType = .no
        accountField.returnKeyType = .next
        accountField.delegate = self
        passwordField.placeholder = "Contraseña:"
        passwordField.setLeftPaddingPoints(10)
        passwordField.customize(false)
        passwordField.isSecureTextEntry = true
        self.view.addSubview(passwordField)
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.returnKeyType = .next
        passwordField.delegate = self
        
        activityInd.hidesWhenStopped = true
        self.view.addSubview(activityInd)
        
        loginButton.backgroundColor =  Utils.UIColorFromRGB(rgbValue: colorPrimaryDark)
        loginButton.setTitle("Acceder", for: .normal)
        loginButton.layer.cornerRadius = 5
        loginButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        self.view.addSubview(loginButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let rect = self.view.bounds
        label.frame = CGRect(x:10, y:60, width:rect.width - 20, height:35)
        accountField.frame = CGRect(x:20, y:label.frame.maxY + 20, width:rect.width - 40, height:35)
        passwordField.frame = CGRect(x:20, y:accountField.frame.maxY + 25, width:rect.width - 40, height:35)
        loginButton.frame = CGRect(x: 40,y:passwordField.frame.maxY+120,width:rect.width - 80,height: 45)
    }
    
    @objc func loginAction() {
        self.view.endEditing(true)
        var message = ""
        guard let account = self.accountField.text,
              let pass = self.passwordField.text
        else {
            return
        }
        if account.isEmpty {
            message = "Por favor ingrese su correo"
        }
        else if pass.isEmpty {
            message = "Por favor ingrese su password"
        }
        if message.isEmpty {
            activityInd.startAnimating()
            Services().loginService(account, pass) { dict in
                DispatchQueue.main.async {  // hay que volver al thread principal para hacer cambios en la UI
                    // TODO: agregar un activity indicator, y desactivarlo aqui (3)
                    self.activityInd.stopAnimating() //se requiere self??? -> si
                    
                    guard let codigo = dict?["code"] as? Int,
                          let mensaje = dict?["message"] as? String
                    else {
                        Utils.showMessage("Ocurrió un error. Reintente más tarde o contacte a servicio al cliente")
                        return
                    }
                    if codigo == 200 {
                        // TODO: Implementar con UserDefaults la comprobación de sesión iniciada (3)
                        let userDefaultsToUse = UserDefaults.standard
                        userDefaultsToUse.set(true, forKey: "customLogin")
                        userDefaultsToUse.set(account, forKey: "userAccount")
                        userDefaultsToUse.synchronize()
                        //NO HACER SEGUE A LOGINOK FUERA DEL HILO PRINCIPAL
                        //self.performSegue(withIdentifier: "loginOK", sender:nil)
                        
                        //SI NO SE NOTIFICA, AUNQUE EL LOGINOK EXISTA Y HAYA CONEXION NO HACE NADA
                        self.delegate?.customLoginViewController(self, performLogin: true)
                    } else {
                        Utils.showMessage(mensaje)
                    }
                }
            }
        }   else {
                Utils.showMessage(message)
            }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == accountField {
            passwordField.becomeFirstResponder()
            return false
        }
        if textField == passwordField {
            passwordField.becomeFirstResponder()
            return false
        }
        return true
    }

}

