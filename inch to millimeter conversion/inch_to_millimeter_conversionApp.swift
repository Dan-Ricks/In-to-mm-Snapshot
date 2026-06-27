//
//  inch_to_millimeter_conversionApp.swift
//  inch to millimeter conversion
//
//  Created by Dan on 6/20/26.
//

import SwiftUI

@main
struct inch_to_millimeter_conversionApp: App {
    @State private var isActive = false

    var body: some Scene {
        WindowGroup {
            if isActive {
                ContentView()
            } else {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isActive = true
                            }
                        }
                    }
            }
        }
    }
}

struct SplashView: View {
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var scale: CGFloat = 0.85

    var body: some View {
        ZStack {
            // Background using the two-color watch mechanics cover image, scaled to cover entire screen
            Image("splash_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("inch to mm converter")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.black)
                    .shadow(color: .white, radius: 3, x: 0, y: 0)
                    .shadow(color: .white, radius: 3, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    .opacity(titleOpacity)
                    .scaleEffect(scale)

                Text("Dan Ricks 2026")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black.opacity(0.9))
                    .shadow(color: .white, radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .opacity(subtitleOpacity)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                titleOpacity = 1.0
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                subtitleOpacity = 1.0
            }
        }
    }
}
