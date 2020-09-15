//
//  NominatimObject.swift
//  Nominatim-iOSPlayground
//
//  Created by Daisuke TONOSAKI on 2020/09/15.
//  Copyright © 2020 Daisuke TONOSAKI. All rights reserved.
//

import Foundation
import CoreLocation

struct NominatimObject: Equatable {
    static func == (lhs: NominatimObject, rhs: NominatimObject) -> Bool {
        return lhs.displayName == rhs.displayName
    }
    
    var displayName: String = ""
    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var importance: Double = 0
    var type: String = ""
}
