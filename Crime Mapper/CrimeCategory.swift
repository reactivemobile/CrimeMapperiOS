//
//  CrimeCategory.swift
//  Crime Mapper
//
//  Created by Donal O'Callaghan on 07/03/2017.
//  Copyright © 2017 Donal O'Callaghan. All rights reserved.
//

import Foundation
import HandyJSON

public struct CrimeCategory: HandyJSON {
    var url: String
    var name: String
    
    public init(){
        url = ""
        name = ""
    }
}
