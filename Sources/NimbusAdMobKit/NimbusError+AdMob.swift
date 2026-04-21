//
//  NimbusError+AdMob.swift
//  NimbusAdMobKit
//
//  Created on 2/23/26.
//  Copyright © 2026 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit

extension NimbusError.Domain {
    static let admob = Self(rawValue: "admob")
}

extension NimbusError {
    static func admob(reason: Reason = .failure, stage: Stage, detail: String? = nil) -> NimbusError {
        NimbusError(reason: reason, domain: .admob, stage: stage, detail: detail)
    }
}
