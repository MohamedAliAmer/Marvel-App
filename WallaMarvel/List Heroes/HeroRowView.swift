import Foundation
import SwiftUI

/// SwiftUI row view for displaying hero information in list
struct HeroRowView: View {
    let model: HeroModel
    
    @Environment(\.sizeCategory) private var sizeCategory
    
    /// Dynamic image size based on accessibility settings
    private var imageSide: CGFloat {
        sizeCategory.isAccessibilityCategory ? 100 : 80
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Hero image with loading states
            ZStack {
                AsyncImage(url: model.imageURL) { phase in
                    switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                        @unknown default:
                            EmptyView()
                    }
                }
            }
            .frame(width: imageSide, height: imageSide)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Hero name with dynamic type support
            Text(model.name)
                .font(.headline) // Dynamic Type
                .minimumScaleFactor(0.8)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.name)
        .accessibilityHint("Opens hero details")
        .accessibilityAddTraits(.isButton)
    }
}