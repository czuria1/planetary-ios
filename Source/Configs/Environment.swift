//
//  Environment.swift
//  Planetary
//
//  Created by Martin Dutra on 2/17/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation

struct Environment {
    
    struct Networks {
        
        static let mainNet = SSBNetwork(
            name: value(for: "PLDefaultNetworkName"),
            key: NetworkKey(base64: value(for: "PLDefaultNetworkKey"))!,
            hmac: nil
        )
        
        static let test = SSBNetwork(
            name: value(for: "PLTestingNetworkName"),
            key: NetworkKey(base64: value(for: "PLTestingNetworkKey"))!,
            hmac: HMACKey(base64: value(for: "PLTestingNetworkHMAC"))!
        )
    }
    
    enum PlanetarySystem {
        
        static let systemPubs: [Star] = {
            Environment.value(for: "PLPlanetarySystem").split(separator: " ").map { Star(invite: String($0)) }
        }()
        
        static let communityPubs: [Star] = {
            Environment.value(for: "PLCommunities").split(separator: " ").map { Star(invite: String($0)) }
        }()
        
        static let planetaryIdentity: Identity = {
            Environment.value(for: "PLPlanetaryIdentity")
        }()
    }
    
    enum TestNetwork {
        static let systemPubs: [Star] = {
            Environment.value(for: "PLTestNetworkPubs").split(separator: " ").map { Star(invite: String($0)) }
        }()
        
        static let communityPubs: [Star] = {
            Environment.value(for: "PLTestNetworkCommunities").split(separator: " ").map { Star(invite: String($0)) }
        }()
    }
    
    private static func value(for key: String) -> String {
        guard let value = Environment.infoDictionary[key] as? String else {
            fatalError("\(key) not set in plist")
        }
        return value
    }
    
    private static func valueIfPresent(for key: String) -> String? {
        if let value = Environment.infoDictionary[key] as? String, !value.isEmpty {
            return value
        }
        return nil
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.current.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()
}
