import SwiftUI
import MapKit

struct MapScreenView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationService: LocationService
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapContent

                // Bottom pollen card
                VStack {
                    Spacer()
                    MapPollenCard(
                        snapshot: viewModel.selectedPollen,
                        isLoading: viewModel.isLoadingPollen
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Recenter button
                VStack {
                    HStack {
                        Spacer()
                        recenterButton
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            // Current location annotation with pollen data
            if let location = locationService.currentLocation {
                if let pollen = viewModel.selectedPollen,
                   viewModel.selectionState == .currentLocation {
                    Annotation("Current Location", coordinate: location.coordinate) {
                        PollenMapAnnotationView(
                            riskLevel: pollen.overallRiskLevel,
                            index: pollen.overallIndex
                        )
                    }
                } else {
                    UserAnnotation()
                }
            }

            // Saved location markers
            ForEach(viewModel.savedLocations) { location in
                Annotation(location.name, coordinate: location.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .onTapGesture {
                            viewModel.selectSavedLocation(location)
                        }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            // Don't auto-fetch on every map move — only explicit actions
        }
        .onTapGesture { position in
            // Note: MapKit in SwiftUI doesn't easily support converting tap to coordinate.
            // For MVP, users use long-press or saved locations. This is a placeholder.
        }
        .onAppear {
            if let location = locationService.currentLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }

    // MARK: - Recenter Button

    private var recenterButton: some View {
        Button {
            if let location = locationService.currentLocation {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
                viewModel.centerOnCurrentLocation()
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
}

#Preview {
    let locationService = LocationService()
    let viewModel = MapViewModel(locationService: locationService)
    MapScreenView(viewModel: viewModel, locationService: locationService)
}
