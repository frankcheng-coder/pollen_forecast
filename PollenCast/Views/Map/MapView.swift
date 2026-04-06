import SwiftUI
import MapKit

struct MapScreenView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationService: LocationService
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                mapContent

                // Controls overlay
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            recenterButton
                            legendView
                        }
                    }
                    Spacer()
                    if viewModel.isLoading {
                        loadingPill
                    }
                }
                .padding()
            }
            .navigationTitle("Pollen Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            // Pollen grid overlay
            ForEach(viewModel.gridCells) { cell in
                MapPolygon(coordinates: cell.corners)
                    .foregroundStyle(cell.riskLevel.color.opacity(0.35))
            }

            // Current location dot
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.onRegionChanged(context.region)
        }
        .onAppear {
            let coord = viewModel.initialCoordinate
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            ))
        }
    }

    // MARK: - Recenter

    private var recenterButton: some View {
        Button {
            if let location = locationService.currentLocation {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                    ))
                }
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.body)
                .padding(12)
                .background(.regularMaterial, in: Circle())
                .shadow(radius: 2)
        }
        .accessibilityLabel("Recenter to my location")
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Pollen Level")
                .font(.caption2.weight(.semibold))
            legendRow(color: .red, label: "Very High")
            legendRow(color: .orange, label: "High")
            legendRow(color: .yellow, label: "Moderate")
            legendRow(color: .green, label: "Low")
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.6))
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption2)
        }
    }

    // MARK: - Loading

    private var loadingPill: some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)
            Text("Loading pollen data…")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 2)
    }
}

#Preview {
    let locationService = LocationService()
    let viewModel = MapViewModel(locationService: locationService)
    MapScreenView(viewModel: viewModel, locationService: locationService)
}
