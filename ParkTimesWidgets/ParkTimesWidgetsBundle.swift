//
//  ParkTimesWidgetsBundle.swift
//  ParkTimesWidgets
//

import WidgetKit
import SwiftUI

@main
struct ParkTimesWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FavoritesWidget()
        ParkActivityWidget()
    }
}
