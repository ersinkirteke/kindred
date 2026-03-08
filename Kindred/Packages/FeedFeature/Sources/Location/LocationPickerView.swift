import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - Location Picker View

/// Bottom sheet for selecting location via GPS or city search
public struct LocationPickerView: View {
    @Bindable var store: StoreOf<FeedReducer>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [CitySearchService.CityResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @AppStorage("lastSelectedCity") private var lastSelectedCity: String = "Istanbul"

    public init(store: StoreOf<FeedReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Use my location button (at top per locked decision)
                useMyLocationButton
                    .padding(.horizontal, KindredSpacing.md)
                    .padding(.top, KindredSpacing.md)

                Divider()
                    .padding(.vertical, KindredSpacing.sm)

                // Search field
                searchField
                    .padding(.horizontal, KindredSpacing.md)

                // Results list
                ScrollView {
                    if searchText.isEmpty {
                        popularCitiesSection
                    } else {
                        searchResultsSection
                    }
                }
            }
            .navigationTitle(String(localized: "Choose Location", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done", bundle: .main)) {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            // Cancel previous search task
            searchTask?.cancel()

            // Debounce search at 300ms
            searchTask = Task {
                // Minimum 2 characters to trigger search
                guard newValue.count >= 2 else {
                    searchResults = []
                    isSearching = false
                    return
                }

                isSearching = true

                // Wait 300ms for debounce
                try? await Task.sleep(nanoseconds: 300_000_000)

                // Check if cancelled
                guard !Task.isCancelled else { return }

                // Perform search
                do {
                    let results = try await CitySearchService.searchCities(query: newValue)
                    guard !Task.isCancelled else { return }
                    searchResults = results
                    isSearching = false
                } catch {
                    guard !Task.isCancelled else { return }
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    // MARK: - Use My Location Button

    private var useMyLocationButton: some View {
        KindredButton(
            store.isRequestingLocation ? String(localized: "Locating...", bundle: .main) : String(localized: "Use my location", bundle: .main),
            style: .secondary
        ) {
            store.send(.useMyLocation)
        }
        .disabled(store.isRequestingLocation)
        .accessibilityLabel(String(localized: "Use my location", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.location_picker.use_location_hint", bundle: .main))
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: KindredSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.kindredTextSecondary)

            TextField(String(localized: "Search cities...", bundle: .main), text: $searchText)
                .font(.kindredBody())
                .foregroundColor(.kindredTextPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.kindredTextSecondary)
                }
                .accessibilityLabel(String(localized: "Clear search", bundle: .main))
            }
        }
        .padding(KindredSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.kindredCardSurface)
        )
    }

    // MARK: - Popular Cities Section

    private var popularCitiesSection: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.sm) {
            Text(String(localized: "Popular Cities", bundle: .main))
                .font(.kindredHeading3())
                .foregroundColor(.kindredTextPrimary)
                .padding(.horizontal, KindredSpacing.md)
                .padding(.top, KindredSpacing.sm)

            ForEach(CitySearchService.popularCities) { city in
                cityRow(city)
                Divider()
                    .padding(.leading, KindredSpacing.md)
            }
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.sm) {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.kindredAccent)
                    Spacer()
                }
                .padding(.vertical, KindredSpacing.lg)
            } else if searchResults.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: KindredSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.kindredTextSecondary)
                        Text(String(localized: "No cities found", bundle: .main))
                            .font(.kindredBody())
                            .foregroundColor(.kindredTextSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, KindredSpacing.xl)
            } else {
                ForEach(searchResults) { city in
                    cityRow(city)
                    Divider()
                        .padding(.leading, KindredSpacing.md)
                }
            }
        }
    }

    // MARK: - City Row

    private func cityRow(_ city: CitySearchService.CityResult) -> some View {
        Button {
            selectCity(city)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.kindredBody())
                        .fontWeight(.semibold)
                        .foregroundColor(.kindredTextPrimary)

                    Text(city.fullName)
                        .font(.kindredCaption())
                        .foregroundColor(.kindredTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.kindredTextSecondary)
            }
            .padding(.horizontal, KindredSpacing.md)
            .padding(.vertical, KindredSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "\(city.name), \(city.fullName)", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.location_picker.select_city_hint", bundle: .main))
    }

    // MARK: - Actions

    private func selectCity(_ city: CitySearchService.CityResult) {
        // Save to UserDefaults
        lastSelectedCity = city.name

        // Update feed with new location
        store.send(.changeLocation(city.name))

        // Dismiss sheet
        dismiss()
    }
}
