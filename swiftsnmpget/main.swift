//
//  main.swift
//  swiftsnmpget
//
//  Created by Darrell Root on 7/2/22.
//

import Foundation
import Network
import SwiftSnmpKit

print("Hello, World!")
let connection = NWConnection(host: "192.168.4.120", port: 161, using: .udp)

connection.stateUpdateHandler = { (newState) in
    switch(newState) {
    case .ready:
        print("ready")
        send()
        receive()
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

let snmpMessage = SnmpMessage(community: "public", command: .getNextRequest, oid: SnmpOid(".1.3.6.1.2.1")!)
let data = snmpMessage.asnData
//let data = Data([0x30,0x26,0x02,0x01,0x01,0x04,0x06,0x70,0x75,0x62,0x6c,0x69,0x63,0xa1,0x19,0x02,0x04,0x2e,0x9d,0xf9,0xf1,0x02,0x01,0x00,0x02,0x01,0x00,0x30,0x0b,0x30,0x09,0x06,0x05,0x2b,0x06,0x01,0x02,0x01,0x05,0x00])
func send() {
    connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({(error) in
        print(error?.localizedDescription ?? "no error")
    })))
}
func receive() {
    connection.receiveMessage { (data,context,isComplet,error) in
        print("Got it")
        guard let data = data else {
            print("no data")
            exit(EXIT_FAILURE)
        }
        guard let snmpMessage = SnmpMessage(data: data) else {
            print("failed to decode snmp message")
            exit(EXIT_FAILURE)
        }
        print(snmpMessage)
        exit(EXIT_SUCCESS)
    }
}
print("before runloop")
RunLoop.main.run()
print("should not get here")

