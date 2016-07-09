import Vapor
import VaporTLS
import Foundation

let VERSION = "0.1.0"

let config = try Config(workingDirectory: workingDirectory)
guard let token = config["bot-config", "token"].string else { throw BotError.missingConfig }

let rtmResponse = try HTTPClient.loadRealtimeApi(token: token)
guard let webSocketURL = rtmResponse.data["url"].string else { throw BotError.invalidResponse }

let app = Application()

try WebSocket.connect(to: webSocketURL, using: HTTPClient<TLSClientStream>.self) { ws in
    print("Connected to \(webSocketURL)")

    ws.onText = { ws, text in
        let event = try JSON.parseString(text)
        print("[event] - \(event)")
        guard
            let channel = event["channel"].string,
            let text = event["text"].string
            else { return }

        if text.hasPrefix("hello") {
            let response = SlackMessage(to: channel, text: "Hi there 👋")
            try ws.send(response)
        } else if text.hasPrefix("version") {
            let response = SlackMessage(to: channel, text: "Current Version: \(VERSION)")
            try ws.send(response)
        } else if text.hasPrefix("server status") {

            let start = NSDate()
            guard let response = try? app.client.get("https://pgorelease.nianticlabs.com/plfe/") else { print("[RESPONSE FAILURE]"); return }

            let responseTime = start.timeIntervalSinceNow * (-1)
            print(responseTime)

            if responseTime < 0.8 {
                guard (try? ws.send(SlackMessage(to: channel, text: "Pokémon GO servers are currently online. Catch 'em all! :pokeball:"))) != nil else {
                    print("[UP FAILURE]")
                    return
                }
            } else if responseTime < 3.0 {
                guard (try? ws.send(SlackMessage(to: channel, text: "The servers are struggling... :muk:"))) != nil else {
                    print("[STRUGGLE FAILURE]")
                    return
                }
            } else {
                guard (try? ws.send(SlackMessage(to: channel, text: ":magmar: Servers are on fire!!! :magmar:"))) != nil else {
                    print("[FIRE FAILURE]")
                    return
                }
            }
        }
    }

    ws.onClose = { ws, _, _, _ in
        print("\n[CLOSED]\n")
    }
}
