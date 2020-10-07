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
    private final  let db: FMDatabase = FMDatabase();
    var groups = ["User"]
    let cdcShareSync = CDCSynchronization()
    
    
    init(syncParameters: [String:String]) {
        super.init()
        let cp: CDCConnectionParameters = CDCConnectionParameters()
        cp.hostName = "helicopter-dev.baccasoft.ru"
        cp.portNumber = 11131
        cp.readTimeout = 60_000
        cp.writeTimeout = 60_000
        cdcShareSync.connectionParameters =  cp
        
        let cdcDB = CDCDatabase()
        let filePath = Bundle.main.url(forResource: "docflow_hel_16", withExtension: "xml")
//        cdcDB.createStructure(byXml: filePath?.absoluteString, database:self.db)
        
        cdcDB.createOrOpen(byXml: filePath?.absoluteString, path: self.db.databasePath())

//        let cdcVarList = [CdcVarName.DEVICE_ID, CdcVarName.USER_ID, CdcVarName.LOGIN, CdcVarName.ACTION_NAME];
        let cdcVarList = [CdcVarName.USER_ID, CdcVarName.LOGIN];
        for varName in cdcVarList
        {
//            var value = syncParameters[varName];
//            value = (value != nil) ? value: ""
//            CDCPlatformVariables.init().setString(varName, stringValue: value)
        }
    }
    
    
    override func execute(syncParameters:[String: String] ) {
        cdcShareSync.execute(db, forGroups: self.groups)
    }

}
