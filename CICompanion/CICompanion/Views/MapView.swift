//
//  MapView.swift
//  CICompanion
//
//  Fullscreen campus map built on Apple MapKit. Shows MapKit's built-in
//  point-of-interest tags, an MKLocalSearch-powered search bar, a back
//  button to return the user to the previous tab, and a user-location
//  button repositioned to the bottom-right.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Local Layout Constants

/// Map-only layout constants. Anything reusable lives in `ViewHelper`.
private enum MapLayout {
    // Camera / region
    static let initialSpanDelta: CLLocationDegrees = 0.012
    static let focusedSpanDelta: CLLocationDegrees = 0.004

    // Top overlay
    static let topBarHorizontalPadding: CGFloat = 14
    static let topBarVerticalPadding: CGFloat = 8
    static let topBarChevronSize: CGFloat = 16
    static let overlayStackSpacing: CGFloat = 10
    static let overlayBottomPadding: CGFloat = 6

    // Search bar
    static let searchFieldCornerRadius: CGFloat = 12
    static let searchFieldVerticalPadding: CGFloat = 10
    static let searchFieldHorizontalPadding: CGFloat = 12
    static let searchIconSize: CGFloat = 14
    static let searchInnerSpacing: CGFloat = 8
    static let searchResultsCornerRadius: CGFloat = 12
    static let searchResultsMaxHeight: CGFloat = 240
    static let searchResultRowVerticalPadding: CGFloat = 10
    static let searchDebounceMillis: UInt64 = 300

    // Bottom overlay
    static let bottomControlsTrailingPadding: CGFloat = 12
    static let bottomControlsBottomPadding: CGFloat = 12
    static let attributionBottomInset: CGFloat = 44
    static let mapOrnamentTopPadding: CGFloat = 8

    // Destination / directions card
    static let destinationCardCornerRadius: CGFloat = 14
    static let destinationCardHorizontalPadding: CGFloat = 16
    static let destinationCardBottomPadding: CGFloat = 16
    static let directionsButtonHeight: CGFloat = 36
    static let directionsButtonHorizontalPadding: CGFloat = 14
    static let routePolylineWidth: CGFloat = 5
    static let routeRegionPaddingFraction: Double = 0.35

    // Pills (used by transport-mode toggles)
    static let pillHorizontalPadding: CGFloat = 12

    // Animation
    static let cameraAnimationDuration: Double = 0.6

    // Shadow
    static let overlayShadowRadius: CGFloat = 8
    static let overlayShadowOpacity: CGFloat = 0.12
    static let overlayShadowYOffset: CGFloat = 2
}

// MARK: - Search Result Wrapper

private struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Route Wrapper

private struct RouteInfo {
    let polyline: MKPolyline
    let expectedTravelTime: TimeInterval
    let distanceMeters: CLLocationDistance
    let transportType: MKDirectionsTransportType
}

// MARK: - Campus Center

private let campusCenter = CLLocationCoordinate2D(latitude: 34.1620, longitude: -119.0437)

// MARK: - Fullscreen Map View

struct MapView: View {
    /// Called when the user taps the back button to dismiss the fullscreen map.
    var onDismiss: () -> Void = {}

    @Namespace private var mapScope

    /// Owns the CoreLocation prompt. Without an explicit request the
    /// permission dialog never appears on first launch.
    @State private var locationManager = CLLocationManager()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: campusCenter,
            span: MKCoordinateSpan(
                latitudeDelta: MapLayout.initialSpanDelta,
                longitudeDelta: MapLayout.initialSpanDelta
            )
        )
    )

    // Search state
    @State private var searchText: String = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearchFocused: Bool = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var searchFieldFocused: Bool

    // Destination + directions state
    @State private var destination: SearchResult?
    @State private var route: RouteInfo?
    @State private var isLoadingRoute: Bool = false
    @State private var routeErrorMessage: String?
    @State private var transportType: MKDirectionsTransportType = .walking

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition, scope: mapScope) {
                UserAnnotation()

                if let destination {
                    Marker(destination.title, coordinate: destination.coordinate)
                        .tint(ViewHelper.accentBlue)
                }

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(ViewHelper.accentBlue, lineWidth: MapLayout.routePolylineWidth)
                }
            }
            .mapControls {
                // Hide default ornaments — we place compass + scale manually
                // below so they don't get clipped by the top overlay (Back
                // button / search bar) or the status-bar battery.
            }
            .ignoresSafeArea(.container, edges: [.top, .horizontal])
            .onTapGesture {
                if isSearchFocused {
                    searchFieldFocused = false
                    isSearchFocused = false
                }
            }

            // Manually-placed map ornaments anchored below the top overlay.
            VStack {
                HStack(alignment: .top) {
                    MapScaleView(scope: mapScope)
                        .padding(.leading, MapLayout.bottomControlsTrailingPadding)
                    Spacer()
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.visible)
                        .padding(.trailing, MapLayout.bottomControlsTrailingPadding)
                }
                .padding(.top, MapLayout.mapOrnamentTopPadding)
                Spacer()
            }
            .allowsHitTesting(true)

            MapUserLocationButton(scope: mapScope)
                .buttonBorderShape(.circle)
                .padding(.trailing, MapLayout.bottomControlsTrailingPadding)
                .padding(.bottom, destination == nil
                         ? MapLayout.bottomControlsBottomPadding
                         : MapLayout.bottomControlsBottomPadding + destinationCardEstimatedHeight)

            if let destination {
                destinationCard(for: destination)
                    .padding(.horizontal, MapLayout.destinationCardHorizontalPadding)
                    .padding(.bottom, MapLayout.destinationCardBottomPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .mapScope(mapScope)
        .safeAreaInset(edge: .top, spacing: 0) {
            topOverlay
        }
        .onAppear {
            requestLocationAccessIfNeeded()
        }
    }

    private func requestLocationAccessIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    // MARK: Top Overlay (Back + Search)

    private var topOverlay: some View {
        VStack(spacing: MapLayout.overlayStackSpacing) {
            topBar
            searchBar
            if isSearchFocused && !searchResults.isEmpty {
                searchResultsList
            }
        }
        .padding(.bottom, MapLayout.overlayBottomPadding)
    }

    // MARK: Top Bar (Back + Title)

    private var topBar: some View {
        let topBarSpacing: CGFloat = ViewHelper.spacing + 4
        let backChevronTextSpacing: CGFloat = 4

        return HStack(spacing: topBarSpacing) {
            Button(action: onDismiss) {
                HStack(spacing: backChevronTextSpacing) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: MapLayout.topBarChevronSize, weight: .semibold))
                    Text("Back")
                        .font(.system(size: ViewHelper.textSize, weight: .semibold))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, MapLayout.topBarHorizontalPadding)
                .padding(.vertical, MapLayout.topBarVerticalPadding)
                .background(.thinMaterial, in: Capsule())
            }

            Spacer()

            Text("Campus Map")
                .font(.system(size: ViewHelper.textSize, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, MapLayout.topBarHorizontalPadding)
                .padding(.vertical, MapLayout.topBarVerticalPadding)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal, ViewHelper.biggerSpacing)
    }

    // MARK: Search Bar

    private var searchBar: some View {
        HStack(spacing: MapLayout.searchInnerSpacing) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: MapLayout.searchIconSize, weight: .semibold))
                .foregroundColor(.secondary)

            TextField("Search or get directions", text: $searchText)
                .font(.system(size: ViewHelper.textSize))
                .foregroundColor(.primary)
                .submitLabel(.search)
                .focused($searchFieldFocused)
                .onChange(of: searchFieldFocused) { _, focused in
                    if focused { isSearchFocused = true }
                }
                .onChange(of: searchText) { _, newValue in
                    debounceSearch(query: newValue)
                }
                .onSubmit {
                    runSearch(query: searchText)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: MapLayout.searchIconSize + 4))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, MapLayout.searchFieldHorizontalPadding)
        .padding(.vertical, MapLayout.searchFieldVerticalPadding)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: MapLayout.searchFieldCornerRadius)
        )
        .shadow(
            color: .black.opacity(MapLayout.overlayShadowOpacity),
            radius: MapLayout.overlayShadowRadius,
            y: MapLayout.overlayShadowYOffset
        )
        .padding(.horizontal, ViewHelper.biggerSpacing)
    }

    // MARK: Search Results List

    private var searchResultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(searchResults) { result in
                    Button {
                        select(result)
                    } label: {
                        searchResultRow(result)
                    }
                    .buttonStyle(.plain)

                    if result != searchResults.last {
                        Divider()
                            .padding(.leading, MapLayout.searchFieldHorizontalPadding)
                    }
                }
            }
        }
        .frame(maxHeight: MapLayout.searchResultsMaxHeight)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: MapLayout.searchResultsCornerRadius)
        )
        .shadow(
            color: .black.opacity(MapLayout.overlayShadowOpacity),
            radius: MapLayout.overlayShadowRadius,
            y: MapLayout.overlayShadowYOffset
        )
        .padding(.horizontal, ViewHelper.biggerSpacing)
    }

    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: MapLayout.searchInnerSpacing + 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: ViewHelper.bigIconSize))
                .foregroundColor(ViewHelper.accentBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: ViewHelper.textSize - 1, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if !result.subtitle.isEmpty {
                    Text(result.subtitle)
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, MapLayout.searchFieldHorizontalPadding)
        .padding(.vertical, MapLayout.searchResultRowVerticalPadding)
        .contentShape(Rectangle())
    }

    // MARK: Search Actions

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: MapLayout.searchDebounceMillis * 1_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { runSearch(query: trimmed) }
        }
    }

    private func runSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = MKCoordinateRegion(
            center: campusCenter,
            span: MKCoordinateSpan(
                latitudeDelta: MapLayout.initialSpanDelta,
                longitudeDelta: MapLayout.initialSpanDelta
            )
        )

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let items = response?.mapItems else { return }
            let mapped: [SearchResult] = items.map { item in
                SearchResult(
                    title: item.name ?? "Unnamed",
                    subtitle: Self.formatAddress(for: item.address),
                    coordinate: item.location.coordinate
                )
            }
            DispatchQueue.main.async {
                self.searchResults = mapped
            }
        }
    }

    private func select(_ result: SearchResult) {
        searchFieldFocused = false
        isSearchFocused = false
        searchResults = []
        searchText = result.title
        destination = result
        route = nil
        routeErrorMessage = nil
        withAnimation(.easeInOut(duration: MapLayout.cameraAnimationDuration)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: result.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: MapLayout.focusedSpanDelta,
                        longitudeDelta: MapLayout.focusedSpanDelta
                    )
                )
            )
        }
        fetchRoute(to: result, mode: transportType)
    }

    private func clearDestination() {
        destination = nil
        route = nil
        routeErrorMessage = nil
        isLoadingRoute = false
    }

    // MARK: Destination Card + Directions

    private var destinationCardEstimatedHeight: CGFloat { 110 }

    private func destinationCard(for result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: ViewHelper.spacing) {
            HStack(alignment: .top, spacing: ViewHelper.spacing + 2) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: ViewHelper.bigIconSize))
                    .foregroundColor(ViewHelper.accentBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.system(size: ViewHelper.textSize - 1, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.system(size: ViewHelper.smallTextSize))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    routeStatusLabel
                }

                Spacer(minLength: 0)

                Button {
                    clearDestination()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: ViewHelper.bigIconSize))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: ViewHelper.spacing) {
                transportToggle(.walking, icon: "figure.walk", label: "Walk")
                transportToggle(.automobile, icon: "car.fill", label: "Drive")
                Spacer()
            }
        }
        .padding(ViewHelper.padding - 2)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: MapLayout.destinationCardCornerRadius)
        )
        .shadow(
            color: .black.opacity(MapLayout.overlayShadowOpacity),
            radius: MapLayout.overlayShadowRadius,
            y: MapLayout.overlayShadowYOffset
        )
    }

    @ViewBuilder
    private var routeStatusLabel: some View {
        if isLoadingRoute {
            Text("Calculating route…")
                .font(.system(size: ViewHelper.smallTextSize))
                .foregroundColor(.secondary)
        } else if let route {
            Text("\(formatTravelTime(route.expectedTravelTime)) · \(formatDistance(route.distanceMeters))")
                .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                .foregroundColor(ViewHelper.accentBlue)
        } else if let routeErrorMessage {
            Text(routeErrorMessage)
                .font(.system(size: ViewHelper.smallTextSize))
                .foregroundColor(.secondary)
        }
    }

    private func transportToggle(
        _ mode: MKDirectionsTransportType,
        icon: String,
        label: String
    ) -> some View {
        let isOn = transportType == mode
        return Button {
            guard transportType != mode else { return }
            transportType = mode
            if let destination {
                fetchRoute(to: destination, mode: mode)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                Text(label)
                    .font(.system(size: ViewHelper.metaTextSize, weight: .semibold))
            }
            .foregroundColor(isOn ? .white : .primary)
            .padding(.horizontal, MapLayout.pillHorizontalPadding)
            .frame(height: MapLayout.directionsButtonHeight)
            .background(
                Group {
                    if isOn {
                        Capsule().fill(ViewHelper.accentBlue)
                    } else {
                        Capsule().fill(.thinMaterial)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private func fetchRoute(to result: SearchResult, mode: MKDirectionsTransportType) {
        guard let userLocation = locationManager.location?.coordinate else {
            routeErrorMessage = "Enable location to see directions."
            isLoadingRoute = false
            return
        }

        isLoadingRoute = true
        routeErrorMessage = nil
        route = nil

        let request = MKDirections.Request()
        request.source = Self.makeMapItem(at: userLocation)
        request.destination = Self.makeMapItem(at: result.coordinate, name: result.title)
        request.transportType = mode

        MKDirections(request: request).calculate { response, error in
            DispatchQueue.main.async {
                self.isLoadingRoute = false
                if let error {
                    self.routeErrorMessage = "Couldn't calculate route: \(error.localizedDescription)"
                    return
                }
                guard let chosen = response?.routes.first else {
                    self.routeErrorMessage = "No route found."
                    return
                }
                self.route = RouteInfo(
                    polyline: chosen.polyline,
                    expectedTravelTime: chosen.expectedTravelTime,
                    distanceMeters: chosen.distance,
                    transportType: mode
                )
                self.fitCamera(to: chosen.polyline)
            }
        }
    }

    private func fitCamera(to polyline: MKPolyline) {
        var rect = polyline.boundingMapRect
        let pad = MapLayout.routeRegionPaddingFraction
        rect = rect.insetBy(dx: -rect.size.width * pad, dy: -rect.size.height * pad)
        withAnimation(.easeInOut(duration: MapLayout.cameraAnimationDuration)) {
            cameraPosition = .rect(rect)
        }
    }

    private func formatTravelTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: max(seconds, 60)) ?? "—"
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: meters)
    }

    private static func formatAddress(for address: MKAddress?) -> String {
        guard let address else { return "" }
        return address.shortAddress ?? address.fullAddress ?? ""
    }

    /// Builds an `MKMapItem` from a coordinate using the iOS 26+
    /// `location:address:` initializer.
    private static func makeMapItem(
        at coordinate: CLLocationCoordinate2D,
        name: String? = nil
    ) -> MKMapItem {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let item = MKMapItem(location: location, address: nil)
        if let name { item.name = name }
        return item
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
