//
//  DiscoveryItem.swift
//  CICompanion
//
//  Created by Emma on 4/30/26.
//

import SwiftUI

protocol DiscoveryItem {
    var title: String { get set }
    var subtitle: String { get set }
    var metaInfoLn1: String { get set }
    var metaInfoLn2: String { get set }
}

struct EventDI: DiscoveryItem {
    var title: String
    
    var subtitle: String
    
    var metaInfoLn1: String
    
    var metaInfoLn2: String
    
}


