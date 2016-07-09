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
            let start = Date()
            let response = try app.client.get("https://pgorelease.nianticlabs.com/plfe/")
            let responseTime = Date().timeIntervalSince(start)
            print(responseTime)
            if responseTime < 1.0 {
                try ws.send(SlackMessage(to: channel, text: "Pokémon GO servers are currently online. Catch 'em all! :pokeball:"))
            } else if responseTime < 3.0 {
                try ws.send(SlackMessage(to: channel, text: "The servers are struggling... :muk:"))
            } else {
                try ws.send(SlackMessage(to: channel, text: ":magmar: Servers are on fire!!! :magmar:"))
            }
        }
    }

    ws.onClose = { ws, _, _, _ in
        print("\n[CLOSED]\n")
    }
}
