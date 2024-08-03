//
//  SharedState.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/4/24.
//

import SwiftUI

class SharedState: ObservableObject {
    @Published var isCooldownActive: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var showOutOfBoundsAlert: Bool = false
    @Published var isReportingOnBehalf: Bool = false
    @Published var isReportingDisabled: Bool = false
}
