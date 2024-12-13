//
//  InternetMonitor.swift
//  Barman
//
//  Created by Azul Alfaro on 13/12/24.
//


import Foundation
import Network

class InternetMonitor {
    //decidir si me sirve que sea un singleton
    var hayConexion = false
    private var monitor = NWPathMonitor()
    var tipoConexionWifi = false
    
    init (){
        //que debe de hacer cuando cambie el estado de la conexion...
        monitor.pathUpdateHandler = {ruta in
            self.hayConexion = ruta.status == .satisfied
            self.tipoConexionWifi = ruta.usesInterfaceType(.wifi)
        }
        //para que comience a revisar si hay cambios...
        //los procesos que pueden tomar mucho timempo o muchos recursos se deben de mandar a background
        monitor.start(queue: DispatchQueue.global(qos: .background))
        
        //se puede colocar aqui el codigo para monitorear
    }
    
    
}

extension Notification.Name {
    static let connectionStatusChanged = Notification.Name("connectionStatusChanged")
}
