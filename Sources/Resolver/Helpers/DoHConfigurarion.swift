import Foundation
import Network

enum DoHConfigurarion: Hashable {
    case adGuard
    case alibaba
    case cloudflare
    case google
    case openDNS
    case quad9

    var httpsURL: URL {
        switch self {
        case .adGuard:
            return URL(string: "https://dns.adguard.com/dns-query")!
        case .alibaba:
            return URL(string: "https://dns.alidns.com/dns-query")!
        case .cloudflare:
            return URL(string: "https://cloudflare-dns.com/dns-query")!
        case .google:
            return URL(string: "https://dns.google/dns-query")!
        case .openDNS:
            return URL(string: "https://doh.opendns.com/dns-query")!
        case .quad9:
            return URL(string: "https://dns.quad9.net/dns-query")!
        }
    }

    var serverAddresses: [NWEndpoint] {
        switch self {
        case .adGuard:
            return [
                NWEndpoint.hostPort(host: "94.140.14.14", port: 443),
                NWEndpoint.hostPort(host: "94.140.15.15", port: 443),
                NWEndpoint.hostPort(host: "2a10:50c0::ad1:ff", port: 443),
                NWEndpoint.hostPort(host: "2a10:50c0::ad2:ff", port: 443)
            ]
        case .alibaba:
            return [
                NWEndpoint.hostPort(host: "223.5.5.5", port: 443),
                NWEndpoint.hostPort(host: "223.6.6.6", port: 443),
                NWEndpoint.hostPort(host: "2400:3200::1", port: 443),
                NWEndpoint.hostPort(host: "2400:3200:baba::1", port: 443)
            ]
        case .cloudflare:
            return [
                NWEndpoint.hostPort(host: "1.1.1.1", port: 443),
                NWEndpoint.hostPort(host: "1.0.0.1", port: 443),
                NWEndpoint.hostPort(host: "2606:4700:4700::1111", port: 443),
                NWEndpoint.hostPort(host: "2606:4700:4700::1001", port: 443)
            ]
        case .google:
            return [
                NWEndpoint.hostPort(host: "8.8.8.8", port: 443),
                NWEndpoint.hostPort(host: "8.8.4.4", port: 443),
                NWEndpoint.hostPort(host: "2001:4860:4860::8888", port: 443),
                NWEndpoint.hostPort(host: "2001:4860:4860::8844", port: 443)
            ]
        case .openDNS:
            return []
        case .quad9:
            return [
                NWEndpoint.hostPort(host: "9.9.9.9", port: 443),
                NWEndpoint.hostPort(host: "149.112.112.112", port: 443),
                NWEndpoint.hostPort(host: "2620:fe::fe", port: 443),
                NWEndpoint.hostPort(host: "2620:fe::9", port: 443)
            ]
        }
    }
}
