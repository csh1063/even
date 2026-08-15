//
//  PhotoAnalysisLiveActivity.swift
//  PhotoAnalysisWidgetExtension
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PhotoAnalysisActivity

struct PhotoAnalysisLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PhotoAnalysisActivityAttributes.self) { context in
            LockScreenView(progress: context.state.progress)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LogoImage(size: 24, forceLight: true)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .foregroundStyle(.white)
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(.white)
                }
            } compactLeading: {
                LogoImage(size: 20, forceLight: true)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2)
            } minimal: {
                LogoImage(size: 20, forceLight: true)
            }
        }
    }
}

private struct LogoImage: View {
    let size: CGFloat
    // 다이나믹 아일랜드는 항상 검정 배경이라, 크림색 배경의 라이트 버전이 또렷하게 보인다.
    // 다크 버전(배경이 거의 검정)을 쓰면 아일랜드 배경에 묻혀 경계가 안 보인다.
    var forceLight: Bool = false

    var body: some View {
        let image = Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))

        if forceLight {
            image.environment(\.colorScheme, .light)
        } else {
            image
        }
    }
}

private struct LockScreenView: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                LogoImage(size: 24)
                Text("사진 분석 중")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)

            ProgressView(value: progress)
                .tint(.white)
        }
        .padding()
    }
}
