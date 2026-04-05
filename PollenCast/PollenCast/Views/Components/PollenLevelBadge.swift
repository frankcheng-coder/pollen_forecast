import SwiftUI

struct PollenLevelBadge: View {
    let riskLevel: PollenRiskLevel
    let showIndex: Bool
    let index: Int?

    init(riskLevel: PollenRiskLevel, index: Int? = nil, showIndex: Bool = true) {
        self.riskLevel = riskLevel
        self.index = index
        self.showIndex = showIndex
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: riskLevel.emoji)
                .font(.caption)
            Text(riskLevel.label)
                .font(.caption.weight(.semibold))
            if showIndex, let index {
                Text("(\(index))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(riskLevel.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(riskLevel.backgroundColor, in: Capsule())
        .accessibilityLabel("Pollen level: \(riskLevel.label)\(showIndex && index != nil ? ", index \(index!)" : "")")
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(PollenRiskLevel.allCases, id: \.rawValue) { level in
            PollenLevelBadge(riskLevel: level, index: level.rawValue)
        }
    }
    .padding()
}
