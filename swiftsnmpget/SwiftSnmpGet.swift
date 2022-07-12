//
//  main.swift
//  swiftsnmpget
//
//  Created by Darrell Root on 7/2/22.
//

import Foundation
import Network
import ArgumentParser
import SwiftSnmpKit

@main
struct SwiftSnmpGet: ParsableCommand {
    // ./swiftsnmpget -c public 192.168.4.120 1.3.6.1.2.1.1.1.0
    static let version = "0.0.10"
    static let commandName = "swiftsnmpget"
    static let discussion = """
    SNMP commands in native Swift and open-source!
    https://github.com/darrellroot/SwiftSnmpKit
    """
    static let configuration = CommandConfiguration(commandName: commandName, abstract: "", usage: "\(commandName) [OPTIONS] AGENT OID", discussion: discussion, version: version, shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    @Option(name: .short, help: "SNMP community") var community: String
    @Argument(help: "SNMP agent IP or hostname") var agent: String
    @Argument(help: "SNMP OID") var oid: String
    
    func run() {
        var connection: NWConnection
        connection = NWConnection(host: NWEndpoint.Host(agent), port: 161, using: .udp)
        let command = SnmpPduType.getRequest
        let snmpMessage = SnmpMessage(community: community, command: command, oid: SnmpOid(oid)!)
        let data = snmpMessage.asnData
        
        connection.stateUpdateHandler = { (newState) in
            switch(newState) {
            case .ready:
                print("ready")
                send(connection: connection, data: data)
                receive(connection: connection)
            case .setup:
                print("setup")
            case .cancelled:
                print("cancelled")
            case .preparing:
                print("Preparing")
            case .waiting(_):
                print("waiting")
            case .failed(_):
                print("failed")
            }
        }
        connection.start(queue: .global())
        RunLoop.main.run()
    }
    func send(connection: NWConnection, data: Data) {
        connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({(error) in
            print(error?.localizedDescription ?? "no error")
        })))
    }
    func receive(connection: NWConnection) {
        connection.receiveMessage { (data,context,isComplet,error) in
            print("Got it")
            guard let data = data else {
                fatalError("no data")
            }
            guard let snmpMessage = SnmpMessage(data: data) else {
                fatalError("Failed to decode snmp message")
            }
            print(snmpMessage)
            SwiftSnmpGet.exit()
        }
    }
}

