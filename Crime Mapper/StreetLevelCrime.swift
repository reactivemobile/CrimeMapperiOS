//
//  StreetLevelCrime.swift
//  Crime Mapper
//
//  Created by Donal O'Callaghan on 07/03/2017.
//  Copyright © 2017 Donal O'Callaghan. All rights reserved.
//

import Foundation
import HandyJSON

public struct StreetLevelCrime: HandyJSON {
    
    var category: String = ""
    var persistent_id: String = ""
    var location_type: String = ""
    var location_subtype: String = ""
    var id: Int = 0
    var location: Location = Location()
    var context: String = ""
    var month: String = ""
    var outcome_status: OutcomeStatus = OutcomeStatus()
    
    public init(){
    }
}

public struct Location: HandyJSON {
    var latitude: String = "";
    
    var longitude: String = "";
    
    var street: Street = Street();
    
    public init(){
    }
}

public struct Street: HandyJSON {
    var id: Int = 0;
    
    var name: String = "";
    
    public init(){
    }
}

public struct OutcomeStatus: HandyJSON {
    var date: String = "";
    
    var category: String = "";
    
    public init(){
    }
}



