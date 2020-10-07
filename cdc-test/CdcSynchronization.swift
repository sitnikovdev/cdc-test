//
//  CdcSynchronization.swift
//  cdc-test
//
//  Created by Oleg Sitnikov on 07.10.2020.
//  Copyright © 2020 Oleg Sitnikov. All rights reserved.
//

import Foundation

class CdcSynchronizationExecutor: AbstractCdcSynchronization {
    
    private static let  TAG: String = "SYNC-CDCEXEC";
    private final  let db: FMDatabase? = nil;
    var groups = ["default"]
    let cdcShareSync = CDCSynchronization()
    
    
    override init() {
        let cp: CDCConnectionParameters = CDCConnectionParameters()
        cp.hostName = "helicopter-dev.baccasoft.ru"
        cp.portNumber = 11131
        cp.readTimeout = 60_000
        cp.writeTimeout = 60_000
        cdcShareSync.connectionParameters =  cp
    }
    
    
    func execute() {
        cdcShareSync.execute(db, forGroups: self.groups)
    }

}
