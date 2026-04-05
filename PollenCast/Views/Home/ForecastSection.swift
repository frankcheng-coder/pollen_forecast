import SwiftUI

struct ForecastSection: View {
    let forecast: PollenForecast?
    let onDayTap: ((PollenDay) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("5-Day Pollen Forecast")
                .font(.headline)

            if let forecast, !forecast.days.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(forecast.days) { day in
                            ForecastDayCard(day: day)
                                .onTapGesture {
                                    onDayTap?(day)
                                }
                        }
                    }
                    .padding(.horizontal, 1) // Prevent shadow clipping
                }
            } else {
                Text("Forecast data unavailable")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Forecast Day Card

struct ForecastDayCard: View {
    let day: PollenDay

    var body: some View {
        VStack(spacing: 8) {
            Text(day.dayLabel)
                .font(.caption.weight(.semibold))

            ZStack {
                Circle()
                    .fill(day.overallRiskLevel.backgroundColor)
                    .frame(width: 44, height: 44)
                Text("\(day.overallIndex)")
                    .font(.headline)
                    .foregroundStyle(day.overallRiskLevel.color)
            }

            Text(day.overallRiskLevel.label)
                .font(.caption2)
                .foregroundStyle(day.overallRiskLevel.color)

            Text(day.shortDateLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSecondaryBackground)
        )
        .accessibilityLabel("\(day.dayLabel), pollen \(day.overallRiskLevel.label), index \(day.overallIndex)")
    }
}

#Preview {
    ForecastSection(
        forecast: MockDataProvider.mockPollenForecast(),
        onDayTap: nil
    )
    .padding()
}
