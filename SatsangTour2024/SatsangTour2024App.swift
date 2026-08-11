//
//  SatsangTour2024App.swift
//  SatsangTour2024
//
//  Created by Aki Kasumi Izumi Borst on 11/08/2026.
//

import SwiftUI
import CoreData

@main
struct SatsangTour2024App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
