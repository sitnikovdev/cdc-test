//
//  AbstractCdcSynchronization.swift
//  cdc-test
//
//  Created by Oleg Sitnikov on 07.10.2020.
//  Copyright © 2020 Oleg Sitnikov. All rights reserved.
//

import Foundation

protocol ISynchronization {
    func startSync()
//    func isStarted() -> Bool
    func addListener(listener: ISyncEventListener)
    func removeListener( listener: ISyncEventListener)
}

enum SynchronizationError {
    case NETWORK
    case DATABASE
    case SERVER
    case AUTH_ERROR
}

enum AuthenticationResult {
          case SUCCESS
          case INVALID_CREDENTIALS
          case INVALID_SERVER_CONFIGURATION
          case ERROR
          case FAIL
          case OFFLINE_NOTEXISTS
          case OFFLINE_DENIED
          case OFFLINE_EXPIRED
          case DISABLED
}

enum SynchronizationResult {
    case SUCCESS
    case FAIL
}

protocol SynchronizationListener {
    func onSynchronizationStart();

    func onSynchronizationError(error: SynchronizationError);

    func onComplete(result: AuthenticationResult);

    func onSynchronizationEnd(result: SynchronizationResult);

    func onSynchronizationGroupEnd(group: String, result: SynchronizationResult);
}


protocol ISyncEventListener {
    func onSyncEvent(event: SyncEvent)
}

class AbstractCdcSynchronization:  ISynchronization, SynchronizationListener {

    private static let TAG: String = "SYNC-ABSCDC"
    private var isStarted: Bool = false
//       final ILogger logger;
     private static let START_SYNC_DELAY = 2
      // for running sync
    private var currentGroup: SyncGroup?
    private var lastAuthenticationResult: AuthenticationResult?
    private var lastSynchronizationError: SynchronizationError?
    
    
    func execute(syncParameters: [String: String]){}

    func onSynchronizationStart() {
    }
    
    func onSynchronizationError(error: SynchronizationError) {
    }
    
    func onComplete(result: AuthenticationResult) {
    }
    
    func onSynchronizationEnd(result: SynchronizationResult) {
    }
    
    func onSynchronizationGroupEnd(group: String, result: SynchronizationResult) {
    }
    
    func startSync() {
        isStarted = true;
//        self.currentGroup =  SyncGroup(group: syncParameters[CdcVarName.GROUP_NAME] ?? "default", vars: syncParameters);
        
        self.lastAuthenticationResult = nil;
        self.lastSynchronizationError = nil;

        execute(syncParameters: ["test":"test"])
    }
    

    func addListener(listener: ISyncEventListener) {
    }
    
    func removeListener(listener: ISyncEventListener) {
    }
    
    
}
