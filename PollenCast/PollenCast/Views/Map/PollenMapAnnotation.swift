import SwiftUI
import MapKit

// MARK: - Pollen Map Annotation Content

struct PollenMapAnnotationView: View {
    let riskLevel: PollenRiskLevel
    let index: Int

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(riskLevel.color)
                    .frame(width: 40, height: 40)
                    .shadow(color: riskLevel.color.opacity(0.4), radius: 4, y: 2)
                Text("\(index)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Triangle pointer
            Triangle()
                .fill(riskLevel.color)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .accessibilityLabel("Pollen index \(index), level \(riskLevel.label)")
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Map Pollen Card (Bottom Sheet Content)

struct MapPollenCard: View {
    let snapshot: PollenSnapshot?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Loading pollen data...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if let snapshot {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pollen at this location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text(snapshot.overallRiskLevel.label)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(snapshot.overallRiskLevel.color)
                            PollenLevelBadge(riskLevel: snapshot.overallRiskLevel, index: snapshot.overallIndex)
                        }
                    }
                    Spacer()
                }

                Text(snapshot.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Quick breakdown
                HStack(spacing: 16) {
                    ForEach(snapshot.typeBreakdowns) { breakdown in
                        VStack(spacing: 4) {
                            Image(systemName: breakdown.category.icon)
                                .foregroundStyle(breakdown.riskLevel.color)
                            Text(breakdown.category.displayName)
                                .font(.caption2)
                            Text(breakdown.riskLevel.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(breakdown.riskLevel.color)
                        }
                    }
                }
            } else {
                Text("Tap a location to see pollen data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

#Preview {
    VStack {
        PollenMapAnnotationView(riskLevel: .high, index: 3)
        MapPollenCard(snapshot: MockDataProvider.mockPollenSnapshot(), isLoading: false)
    }
    .padding()
}
