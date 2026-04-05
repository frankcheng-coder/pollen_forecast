import SwiftUI

struct HealthGuidanceSection: View {
    let recommendation: RecommendationSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Guidance")
                .font(.headline)

            if let recommendation {
                // Headline with rating
                HStack(spacing: 10) {
                    Image(systemName: recommendation.outdoorRating.icon)
                        .font(.title2)
                        .foregroundStyle(recommendation.outdoorRating.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Outdoor Rating: \(recommendation.outdoorRating.label)")
                            .font(.subheadline.weight(.semibold))
                        Text(recommendation.headline)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(recommendation.outdoorRating.color.opacity(0.1))
                )

                // Detail items
                ForEach(Array(recommendation.details.enumerated()), id: \.offset) { _, detail in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }

                // Best time hint
                if let bestTime = recommendation.bestTimeHint {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(bestTime)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.08))
                    )
                }
            } else {
                Text("Recommendations will appear once pollen data loads.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HealthGuidanceSection(recommendation: MockDataProvider.mockRecommendation())
        .padding()
}
