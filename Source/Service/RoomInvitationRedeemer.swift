//
//  RoomInvitationRedeemer.swift
//  Planetary
//
//  Created by Matthew Lorentz on 8/3/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger

enum RoomInvitationRedeemer {
    
    enum RoomInvitationError: Error, LocalizedError {
        
        case invalidURL
        case invitationRedemptionFailedWithReason(String)
        case invitationRedemptionFailed
        case notLoggedIn
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return Text.Error.invalidRoomURL.text
            case .invitationRedemptionFailedWithReason(let reason):
                return Text.Error.invitationRedemptionFailedWithReason.text(["reason": reason])
            case .invitationRedemptionFailed:
                return Text.Error.invitationRedemptionFailed.text
            case .notLoggedIn:
                return Text.Error.notLoggedIn.text
            }
        }
    }
    
    struct ClaimInvitationRequest: Codable {
        var id: String
        var invite: String
    }
    
    struct ClaimInvitationResponse: Codable {
        var status: String
        var multiserverAddress: String?
        var error: String?
    }
    
    static func canRedeem(_ url: URL) -> Bool {
        guard url.scheme == URL.ssbScheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.path == "experimental",
            let queryParams = components.queryItems,
            let actionParam = queryParams.first(where: { $0.name == "action" }),
            actionParam.value == "claim-http-invite",
            queryParams.first(where: { $0.name == "invite" })?.value != nil,
            let postToParam = queryParams.first(where: { $0.name == "postTo" })?.value,
            URL(string: postToParam) != nil else {
            
            return false
        }
        
        return true
    }
        
    static func redeem(_ url: URL, in controller: AppController, bot: Bot) async {
        guard url.scheme == URL.ssbScheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.path == "experimental",
            let queryParams = components.queryItems,
            let actionParam = queryParams.first(where: { $0.name == "action" }),
            actionParam.value == "claim-http-invite",
            let inviteCode = queryParams.first(where: { $0.name == "invite" })?.value,
            let postToParam = queryParams.first(where: { $0.name == "postTo" })?.value,
            let postToURL = URL(string: postToParam) else {
            
            Log.error("invalid room URL: \(url.absoluteURL)")
            await controller.topViewController.alert(error: RoomInvitationError.invalidURL)
            return
        }
        
        guard let identity = bot.identity else {
            Log.error("missing identity for room invitation redemption: \(url.absoluteURL)")
            await controller.topViewController.alert(error: RoomInvitationError.notLoggedIn)
            return
        }
        
        do {
            var request = URLRequest(url: postToURL)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let claimInvitationRequest = ClaimInvitationRequest(id: identity, invite: inviteCode)
            request.httpBody = try JSONEncoder().encode(claimInvitationRequest)
            let (responseData, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ClaimInvitationResponse.self, from: responseData)
            
            if response.status == "successful",
                let addressString = response.multiserverAddress,
                let address = MultiserverAddress(string: addressString) {
                
                let room = Room(address: address)
                try await bot.insert(room: room)
                await controller.showToast(Text.invitationRedeemed.text)
            } else {
                Log.error("Got failure response from room: \(String(describing: responseData.string))")
                if let errorMessage = response.error {
                    await controller.topViewController.alert(
                        error: RoomInvitationError.invitationRedemptionFailedWithReason(errorMessage)
                    )
                }
            }
        } catch {
            Log.optional(error)
            await controller.topViewController.alert(
                error: RoomInvitationError.invitationRedemptionFailedWithReason(error.localizedDescription)
            )
        }
    }
}
