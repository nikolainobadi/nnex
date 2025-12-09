//
//  DefaultDateProvider.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/20/25.
//

import Foundation

struct DefaultDateProvider: DateProvider {
    var currentDate: Date { Date() }
}
