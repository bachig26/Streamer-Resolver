import Foundation
import SwiftUI
import Resolver
import AVKit

public struct MoviesDetailsView: View {
    @State private var movie: Movie?
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
        ScrollView {
            if let movie = movie {
                VStack {
                    AsyncImage(
                        url: movie.posterURL,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 100)
                        },
                        placeholder: {
                            ProgressView()
                        }
                    )
                    Button {
                        self.isShowingSources = true
                    } label: {
                        Image(systemName: "play")
                            .font(.system(size: 42))
                        Text("Play")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                }
            }
        }
        .navigationTitle(movie?.title ?? "")
        .task(refreshTask)
        .alert("Sources", isPresented: $isShowingSources) {
            if let movie = movie, let sources = movie.sources {
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
    }

    @Sendable
    private func refreshTask() {
        Task {
            self.movie = try await provider.fetchMovieDetails(for: self.url)
        }
    }

    @Sendable
    private func fetchSource(source: Source) {
        Task {
            self.selectedStream = try await HostsResolver.resloveURL(url: source.hostURL).first
        }
    }

}
