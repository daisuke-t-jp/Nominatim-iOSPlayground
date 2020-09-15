//
//  String+Ex.swift
//  Nominatim-iOSPlayground
//
//  Created by Daisuke TONOSAKI on 2020/09/15.
//  Copyright © 2020 Daisuke TONOSAKI. All rights reserved.
//

import Foundation

extension String {
    
    var urlEncode: String {
        let charset = CharacterSet.alphanumerics.union(.init(charactersIn: "/?-._~"))
        let str = removingPercentEncoding ?? self
        
        return str.addingPercentEncoding(withAllowedCharacters: charset) ?? str
    }
    
}
