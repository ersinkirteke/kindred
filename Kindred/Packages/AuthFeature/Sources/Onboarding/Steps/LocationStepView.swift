import SwiftUI
import ComposableArchitecture
import DesignSystem
import FeedFeature
import MapKit

struct LocationStepView: View {
    let store: StoreOf<OnboardingReducer>

    var body: some View {
        VStack(spacing: 0) {
            // Skip button at top-right
            HStack {
                Spacer()
                Button {
                    store.send(.skipStep)
                } label: {
                    Text(String(localized: "Skip", bundle: .main))
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                }
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.top, KindredSpacing.md)
                .accessibilityLabel(String(localized: "accessibility.onboarding_location.skip", bundle: .main))
            }

            Spacer()

            // Location icon
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.kindredAccent)
                .padding(.bottom, KindredSpacing.lg)

            // Heading
            Text(String(localized: "onboarding.location.title", bundle: .main))
                .font(.kindredHeading1())
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, KindredSpacing.xl)
                .padding(.horizontal, KindredSpacing.lg)

            // Location buttons
            VStack(spacing: KindredSpacing.md) {
                // Use my location button
                if store.isRequestingLocation {
                    HStack(spacing: KindredSpacing.sm) {
                        ProgressView()
                            .tint(.kindredAccent)
                        Text(String(localized: "onboarding.location.getting_location", bundle: .main))
                            .font(.kindredBody())
                            .foregroundColor(.kindredTextSecondary)
                    }
                    .frame(height: 56)
                } else {
                    KindredButton(String(localized: "onboarding.location.use_my_location", bundle: .main), style: .primary) {
                        // Request permission directly from main thread (SwiftUI button action)
                        // before entering TCA effect, to ensure the system dialog shows
                        LocationManager.shared?.requestPermission()
                        store.send(.requestLocationPermission)
                    }
                    .accessibilityLabel(String(localized: "accessibility.onboarding_location.use_location", bundle: .main))
                }

                // Manual city entry button
                KindredButton(String(localized: "onboarding.location.enter_manually", bundle: .main), style: .secondary) {
                    store.send(.showManualCityPicker)
                }
                .accessibilityLabel(String(localized: "accessibility.onboarding_location.enter_manually", bundle: .main))

                // Permission denied explanation
                if store.locationAuthStatus == .denied {
                    Text(String(localized: "onboarding.location.permission_denied", bundle: .main))
                        .font(.kindredCaption())
                        .foregroundColor(.kindredTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, KindredSpacing.sm)
                        .padding(.horizontal, KindredSpacing.md)
                }

            }
            .padding(.horizontal, KindredSpacing.lg)

            Spacer()
        }
        .background(Color.kindredBackground)
        .sheet(isPresented: Binding(
            get: { store.showCityPicker },
            set: { if !$0 { store.send(.dismissCityPicker) } }
        )) {
            CityPickerView(store: store)
        }
    }
}

// MARK: - City Picker View

struct CityPickerView: View {
    let store: StoreOf<OnboardingReducer>
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.kindredTextSecondary)

                    TextField(String(localized: "onboarding.location.search_placeholder", bundle: .main), text: $searchText)
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextPrimary)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.kindredTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, KindredSpacing.md)
                .padding(.vertical, KindredSpacing.sm)
                .background(Color.kindredCardSurface)
                .cornerRadius(12)
                .padding(.horizontal, KindredSpacing.lg)
                .padding(.vertical, KindredSpacing.md)

                Divider()

                // Search results
                if isSearching {
                    ProgressView()
                        .padding(.top, KindredSpacing.xl)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text(String(localized: "onboarding.location.no_cities_found", bundle: .main))
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                        .padding(.top, KindredSpacing.xl)
                } else {
                    List {
                        ForEach(searchResults, id: \.placemark.name) { mapItem in
                            Button {
                                if let city = mapItem.placemark.locality ?? mapItem.placemark.name {
                                    store.send(.citySelected(city))
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mapItem.placemark.locality ?? mapItem.placemark.name ?? "Unknown")
                                        .font(.kindredBody())
                                        .foregroundColor(.kindredTextPrimary)

                                    if let country = mapItem.placemark.country {
                                        Text(country)
                                            .font(.kindredCaption())
                                            .foregroundColor(.kindredTextSecondary)
                                    }
                                }
                                .padding(.vertical, KindredSpacing.xs)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle(String(localized: "onboarding.location.select_city", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.dismissCityPicker)
                    } label: {
                        Text(String(localized: "Cancel", bundle: .main))
                            .font(.kindredBody())
                            .foregroundColor(.kindredAccent)
                    }
                }
            }
        }
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.resultTypes = .address

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            isSearching = false

            guard let response = response else {
                searchResults = []
                return
            }

            // Filter for city-level results
            searchResults = response.mapItems.filter { item in
                item.placemark.locality != nil
            }
        }
    }
}
