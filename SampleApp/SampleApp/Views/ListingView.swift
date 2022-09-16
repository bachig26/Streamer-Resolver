import Foundation
import SwiftUI
import Resolver

public struct ListingView: View {
    private let mediaContent: [MediaContent]
    private let provider: Provider

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: 90), spacing: 5)]
    }
    public init(mediaContent: [MediaContent], provider: Provider) {
        self.mediaContent = mediaContent
        self.provider = provider
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItems) {
                ForEach(mediaContent, id: \.self) { media in
                    VStack {
                        NavigationLink(value: media) {
                            AsyncImage(
                                url: media.posterURL,
                                content: { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 90)
                                },
                                placeholder: {
                                    ProgressView()
                                }
                            )            }
                        Text(media.title)
                    }
                }
            }.navigationDestination(for: MediaContent.self) { media in
                if media.type == .movie {
                    MoviesDetailsView(url: media.webURL, provider: provider)
                } else {
                    TVShowDetailsView(url: media.webURL, provider: provider)
                }
            }
        }
    }

}
