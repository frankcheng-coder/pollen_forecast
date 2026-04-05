import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel: DetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    LoadingStateView(message: "Loading details...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let day = viewModel.pollenDay {
                    // Header
                    detailHeader(day: day)

                    // Pollen type breakdown
                    pollenBreakdownSection(day: day)

                    // Weather detail
                    if let weather = viewModel.dailyWeather {
                        weatherDetailSection(weather: weather)
                    }

                    // Recommendation
                    if let recommendation = viewModel.recommendation {
                        HealthGuidanceSection(recommendation: recommendation)
                    }

                    Spacer(minLength: 20)
                } else {
                    ErrorStateView("No detail data available")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(viewModel.locationName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private func detailHeader(day: PollenDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.dayLabel)
                    .font(.title2.weight(.bold))
                Text(day.shortDateLabel)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 12) {
                PollenLevelBadge(riskLevel: day.overallRiskLevel, index: day.overallIndex)

                if let dominant = day.dominantType {
                    Text("Driven by \(dominant.category.displayName.lowercased()) pollen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Pollen Breakdown

    private func pollenBreakdownSection(day: PollenDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pollen Breakdown")
                .font(.headline)

            ForEach(day.typeBreakdowns) { breakdown in
                HStack {
                    Image(systemName: breakdown.category.icon)
                        .font(.title3)
                        .foregroundStyle(breakdown.riskLevel.color)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(breakdown.displayName)
                            .font(.body.weight(.medium))
                        if breakdown.inSeason {
                            Text("Currently in season")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    PollenLevelBadge(riskLevel: breakdown.riskLevel, index: breakdown.indexValue, showIndex: true)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appSecondaryBackground)
        )
    }

    // MARK: - Weather Detail

    private func weatherDetailSection(weather: DailyWeather) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                weatherDetailItem(icon: weather.condition.icon, label: "Condition", value: weather.condition.label)
                weatherDetailItem(icon: "thermometer", label: "High / Low", value: "\(Int(weather.highTemperature))° / \(Int(weather.lowTemperature))°")
                weatherDetailItem(icon: "cloud.rain", label: "Rain Chance", value: "\(Int(weather.precipitationChance * 100))%")
                weatherDetailItem(icon: "wind", label: "Wind", value: "\(Int(weather.windSpeed)) km/h")
                weatherDetailItem(icon: "sun.max", label: "UV Index", value: "\(weather.uvIndex)")
                weatherDetailItem(icon: "humidity.fill", label: "Humidity", value: "\(Int(weather.humidity))%")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appSecondaryBackground)
        )
    }

    private func weatherDetailItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }

            Spacer()
        }
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    NavigationStack {
        let vm = DetailViewModel(locationName: "San Francisco")
        let _ = vm.loadDetail(
            for: MockDataProvider.mockPollenForecast().days.first!,
            weather: MockDataProvider.mockDailyWeather().first
        )
        DetailView(viewModel: vm)
    }
}
