//
//  SyncGroup.swift
//  cdc-test
//
//  Created by Oleg Sitnikov on 07.10.2020.
//  Copyright © 2020 Oleg Sitnikov. All rights reserved.
//

import Foundation

class SyncGroup {
    private final var groupName:String
    private final var syncVars: [String:String]
    
    init(group: String, vars: [String: String]) {
        self.groupName = group
        self.syncVars = vars
    }
}
