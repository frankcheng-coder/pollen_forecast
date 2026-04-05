import SwiftUI

struct PollenTypesSection: View {
    let breakdowns: [PollenTypeBreakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pollen Types")
                .font(.headline)

            if breakdowns.isEmpty {
                Text("No pollen type data available")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(breakdowns) { breakdown in
                    PollenTypeRow(breakdown: breakdown)
                }
            }
        }
    }
}

struct PollenTypeRow: View {
    let breakdown: PollenTypeBreakdown

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: breakdown.category.icon)
                .font(.title3)
                .foregroundStyle(breakdown.riskLevel.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(breakdown.displayName)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(breakdown.riskLevel.label)
                        .font(.caption)
                        .foregroundStyle(breakdown.riskLevel.color)
                    if breakdown.inSeason {
                        Text("In Season")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // Bar indicator
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    Capsule()
                        .fill(breakdown.riskLevel.color)
                        .frame(width: barWidth(in: geo.size.width), height: 8)
                }
                .frame(height: geo.size.height)
            }
            .frame(width: 60, height: 20)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appSecondaryBackground)
        )
        .accessibilityLabel("\(breakdown.displayName) pollen: \(breakdown.riskLevel.label)\(breakdown.inSeason ? ", in season" : "")")
    }

    private func barWidth(in totalWidth: CGFloat) -> CGFloat {
        let fraction = CGFloat(breakdown.riskLevel.rawValue) / CGFloat(PollenRiskLevel.veryHigh.rawValue)
        return max(4, totalWidth * fraction)
    }
}

#Preview {
    PollenTypesSection(breakdowns: MockDataProvider.mockPollenBreakdowns())
        .padding()
}
