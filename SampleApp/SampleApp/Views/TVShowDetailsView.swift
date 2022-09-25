import Foundation
import SwiftUI
import Resolver
import AVKit

public struct TVShowDetailsView: View {
    @State private var tvshow: TVshow?
    @State private var selectedEpisode: Episode?
    @State private var selectedStream: Resolver.Stream?

    @State var isShowingPlayer: Bool = false
    @State var isShowingSources: Bool = false

    private let provider: Provider
    private let url: URL

    public init(url: URL, provider: Provider ) {
        self.url = url
        self.provider = provider
    }

    public var body: some View {
        if let tvshow = tvshow {
            ScrollView {
                AsyncImage(
                    url: tvshow.posterURL,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 100)
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                ForEach(tvshow.seasons ?? []) { season in
                    Text("Season \(season.seasonNumber)")
                    ForEach(season.episodes ?? []) { ep in
                        Button(" Ep \(ep.number)") {
                            self.selectedEpisode = ep
                            self.isShowingSources = true
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }

            }

            .navigationTitle(tvshow.title)
            .alert("Sources", isPresented: $isShowingSources) {
                if let selectedEpisode = selectedEpisode, let sources = selectedEpisode.sources {
                    ForEach(sources, id: \.self) { source  in
                        Button(source.hostURL.absoluteString) {
                            fetchSource(source: source)
                        }
                    }
                }
                Button("Cancel") {}
            }
            .sheet(item: $selectedStream) { stream in
                if let stream = stream {
                    let player = HeadersAVPlayer(stream: stream)
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            player.play()
                        }
                } else {
                    Text("Stream failed")
                }
            }

        } else {
            Text("Loading")
                .task(refreshTask)

        }
    }

    @Sendable
    private func refreshTask() {
        Task {
            self.tvshow = try await provider.fetchTVShowDetails(for: url)
        }
    }

    @Sendable
    private func fetchSource(source: Source) {
        Task {
            self.selectedStream = try await HostsResolver.resloveURL(url: source.hostURL).first
        }
    }

}
