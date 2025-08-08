import Foundation
import SwiftUI

struct HeroDetailScreen: View {
    let hero: CharacterDataModel
    @State private var showHiRes = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let lowURL = URL(string: "\(hero.thumbnail.path)/portrait_medium.\(hero.thumbnail.`extension`)"),
                   let highURL = URL(string: "\(hero.thumbnail.path)/portrait_uncanny.\(hero.thumbnail.`extension`)") {
                    ZStack {
                        AsyncImage(url: lowURL) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    ProgressView()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 320)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 320)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 320)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        if showHiRes {
                            AsyncImage(url: highURL) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 320)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 320)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .transition(.opacity)
                                case .failure:
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 320)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Hero image")
                    .accessibilityHint("High resolution image loads after navigation")
                }

                Text(hero.name)
                    .font(.title)
                    .bold()
                    .accessibilityIdentifier("hero-detail-name")

                if hero.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No description available.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("No description available")
                } else {
                    Text(hero.description)
                        .font(.body)
                        .textSelection(.enabled)
                }

                StatsGrid(comics: hero.comics?.available ?? 0,
                          series: hero.series?.available ?? 0,
                          stories: hero.stories?.available ?? 0,
                          events: hero.events?.available ?? 0)

                DetailSectionList(title: "Comics", items: hero.comics?.itemNames ?? [])
                DetailSectionList(title: "Series", items: hero.series?.itemNames ?? [])
                DetailSectionList(title: "Stories", items: hero.stories?.itemNames ?? [])
                DetailSectionList(title: "Events", items: hero.events?.itemNames ?? [])

                Spacer(minLength: 12)
            }
            .padding()
        }
        .onAppear { showHiRes = true }
        .onChange(of: hero.id) { _, _ in
            showHiRes = false
            if #available(iOS 18.0, *) {
                withAnimation(.easeInOut(duration: 0.25)) { showHiRes = true }
            } else {
                showHiRes = true
            }
        }
        .navigationTitle("Details")
    }
}

private struct StatsGrid: View {
    let comics: Int
    let series: Int
    let stories: Int
    let events: Int

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatTile(value: comics, label: "Comics")
            StatTile(value: series, label: "Series")
            StatTile(value: stories, label: "Stories")
            StatTile(value: events, label: "Events")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hero statistics")
    }
}

private struct StatTile: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title2) // Scales with Dynamic Type
                .bold()
                .minimumScaleFactor(0.6)
                .accessibilityIdentifier("stat-\(label.lowercased())-value")
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("stat-\(label.lowercased())-label")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel("\(label) \(value)")
    }
}

private struct DetailSectionList: View {
    let title: String
    let items: [String]
    @State private var expanded = false

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if items.count > 5 {
                        Button(expanded ? "Show less" : "Show more (\(items.count))") {
                            expanded.toggle()
                        }
                        .font(.footnote)
                        .accessibilityLabel(expanded ? "Show fewer \(title)" : "Show more \(title)")
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    ForEach((expanded ? items : Array(items.prefix(5))), id: \.self) { name in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 6)
                                .accessibilityHidden(true) // Decorative
                            Text(name)
                                .font(.subheadline)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(title) section")
        }
    }
}

private extension ItemList {
    var itemNames: [String] {
        (items ?? []).map { $0.name }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
