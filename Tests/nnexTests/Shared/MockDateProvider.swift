//
//  MockDateProvider.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/9/25.
//

import Foundation
@testable import nnex

struct MockDateProvider: DateProvider {
    let currentDate: Date
    
    init(date: Date) {
        self.currentDate = date
    }
}
