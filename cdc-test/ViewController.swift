//
//  ViewController.swift
//  cdc-test
//
//  Created by Oleg Sitnikov on 07.10.2020.
//  Copyright © 2020 Oleg Sitnikov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var delegate: AbstractCdcSynchronization?
    

     static let SCHEMA_NAME = "docflow_hel_16.xml";
     static let DATA_BASE_NAME = "docflow.db";
     static let serverHost = "helicopter-dev.baccasoft.ru";
     static let serverPort = 11131;
     static let serverConnectionTimeout = 6 * 60 * 1000;
     static let serverReadTimeout = 6 * 60 * 1000;
     static let serverSecureConnection = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Добавляем слушателя событий синхронизации.
        NotificationCenter.default.addObserver(self, selector: #selector(self.onSync), name: NSNotification.Name(rawValue: CDC_PLATFORM_EVENT), object: nil)
        
        let button = UIButton(frame: CGRect(x: 100,
                                            y: 100,
                                            width: 200,
                                            height: 60))
        button.setTitle("Test",
                        for: .normal)
        button.setTitleColor(.systemBlue,
                             for: .normal)
        
        button.addTarget(self,
                         action: #selector(buttonAction),
                         for: .touchUpInside)
        
        self.view.addSubview(button)
        
       let syncVars = [
            CdcVarName.LOGIN : "md5",
            CdcVarName.DEVICE_ID : "",
            CdcVarName.USER_ID: "0"
        ]
        
        self.delegate = CdcSynchronizationExecutor(syncParameters: syncVars)
        
    }
    
    @objc
    func buttonAction() {
        print("Button pressed")

        self.delegate?.startSync()

    }

    
    @objc func onSync(notification: Notification) {
        if let result = notification.userInfo?[CDC_PLATFORM_EVENT_INFO_TYPE] as? NSInteger {
            print(result)
        }

    }
    

}

