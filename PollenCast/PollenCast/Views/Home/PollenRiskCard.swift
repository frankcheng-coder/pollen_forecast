import SwiftUI

struct PollenRiskCard: View {
    let snapshot: PollenSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Pollen")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(snapshot.overallRiskLevel.label)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(snapshot.overallRiskLevel.color)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(snapshot.overallRiskLevel.backgroundColor)
                            .frame(width: 64, height: 64)
                        VStack(spacing: 2) {
                            Text("\(snapshot.overallIndex)")
                                .font(.title.weight(.bold))
                                .foregroundStyle(snapshot.overallRiskLevel.color)
                            Text("index")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Pollen index \(snapshot.overallIndex)")
                }

                Text(snapshot.summaryText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Pollen")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("--")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Text("Pollen data unavailable")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSecondaryBackground)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pollen risk card")
    }
}

#Preview {
    VStack {
        PollenRiskCard(snapshot: MockDataProvider.mockPollenSnapshot())
        PollenRiskCard(snapshot: nil)
    }
    .padding()
}
