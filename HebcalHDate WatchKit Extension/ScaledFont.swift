//
//  ScaledFont.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/29/21.
//

import Foundation
import SwiftUI

struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var size: CGFloat
    var weight: Font.Weight
    var design: Font.Design

    func body(content: Content) -> some View {
       let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return content.font(.system(size: scaledSize, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight, design: Font.Design) -> some View {
        return self.modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}
