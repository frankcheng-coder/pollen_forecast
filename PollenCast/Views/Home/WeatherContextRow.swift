import SwiftUI

struct WeatherContextRow: View {
    let weather: WeatherContext?

    var body: some View {
        if let weather {
            HStack(spacing: 0) {
                weatherItem(icon: weather.condition.icon, value: weather.temperatureFormatted, label: "Temp")
                Divider().frame(height: 32)
                weatherItem(icon: "humidity.fill", value: weather.humidityFormatted, label: "Humidity")
                Divider().frame(height: 32)
                weatherItem(icon: "wind", value: weather.windFormatted, label: "Wind")
                Divider().frame(height: 32)
                weatherItem(icon: "cloud.rain", value: weather.precipitationFormatted, label: "Rain")
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondaryBackground)
            )
        } else {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Loading weather...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondaryBackground)
            )
        }
    }

    private func weatherItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    VStack {
        WeatherContextRow(weather: MockDataProvider.mockWeatherContext())
        WeatherContextRow(weather: nil)
    }
    .padding()
}
