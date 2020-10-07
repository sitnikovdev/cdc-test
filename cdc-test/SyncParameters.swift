//
//  SyncParameters.swift
//  cdc-test
//
//  Created by Oleg Sitnikov on 07.10.2020.
//  Copyright © 2020 Oleg Sitnikov. All rights reserved.
//

import Foundation

 class SyncParameters {
    private final var  groupName: String;
    private final var login: String;
    private final var password: String;
    private final var  syncVars: SyncVars;

    init(groupName: String, login: String,  password: String,  syncVars: SyncVars) {
        self.groupName = groupName;
        self.login = login;
        self.password = password;
        self.syncVars = syncVars;
    }
    
}

//extension SyncParameters: CustomStringConvertible {
//    var description: String {
//        return "SyncParameters{" +
//            "groupName='" + groupName + "'" +
//            ", login='" + login + "'" +
//            ", password='" + password + "'" +
//            ", cdcVars=" + syncVars + "}"
//}
//}
