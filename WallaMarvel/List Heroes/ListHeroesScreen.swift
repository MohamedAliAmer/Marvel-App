import Foundation
import SwiftUI

/// SwiftUI screen displaying paginated list of Marvel heroes with search
struct ListHeroesScreen: View {
    @StateObject private var store: ListHeroesUIStore
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>? = nil

    /// Initialize with presenter dependency
    init(presenter: ListHeroesPresenterProtocol) {
        _store = StateObject(wrappedValue: ListHeroesUIStore(presenter: presenter))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Hero list with tap and pagination handling
                    ForEach(store.items, id: \.id) { model in
                        HeroRowView(model: model)
                            .contentShape(Rectangle())
                            .onTapGesture { store.didSelectRow(with: model.id) }
                            .onAppear { store.loadMoreIfNeeded(for: model.id) }
                    }
                } footer: {
                    // Pagination loading indicator
                    if store.isPaginating && !store.items.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                                .id(UUID())
                                .accessibilityLabel("Loading more results")
                                .accessibilityHint("Fetching additional heroes")
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .id("pagination-footer")
                        .onAppear {
                            if let lastId = store.items.last?.id {
                                store.loadMoreIfNeeded(for: lastId)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .animation(.default, value: store.isPaginating)
            .animation(.default, value: store.isLoading)
            .navigationTitle(store.screenTitle)
            .overlay(alignment: .top) {
                // Loading indicators
                if store.isLoading && store.items.isEmpty {
                    ProgressView()
                } else if store.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading…")
                            .font(.footnote)
                    }
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading")
                    .accessibilityHint("Please wait while content updates")
                }
            }
            .overlay {
                // Error state with retry option
                if store.items.isEmpty,
                   let msg = store.errorMessage,
                   !msg.isEmpty,
                   !store.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .imageScale(.large)
                            .font(.largeTitle)
                        Text("Something went wrong")
                            .font(.headline)
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task { await store.refreshAwaitingCompletion() }
                        } label: {
                            Text("Retry")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Retry loading")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search heroes")
            .accessibilityInputLabels(["Search heroes"])
            .refreshable {
                await store.refreshAwaitingCompletion()
            }
            .onChange(of: searchText) { _, newValue in
                // Debounced search to avoid excessive API calls
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    if Task.isCancelled { return }
                    store.search(newValue)
                }
            }
            .onAppear { store.ensureLoaded() }
            .alert("Error", isPresented: .init(
                get: {
                    if let m = store.errorMessage { return !m.isEmpty }
                    return false
                },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .navigationDestination(item: $store.selectedHero) { hero in
                HeroDetailScreen(hero: hero)
            }
        }
        .dynamicTypeSize(.xSmall ... .accessibility5)
    }
}