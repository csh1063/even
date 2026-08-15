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
                    Image(systemName: "photo.stack")
                        .foregroundStyle(.white)
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
                Image(systemName: "photo.stack")
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2)
            } minimal: {
                Image(systemName: "photo.stack")
            }
        }
    }
}

private struct LockScreenView: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "photo.stack")
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
