//
//  main.swift
//  swiftsnmpv3get
//
//  Created by Darrell Root on 7/2/22.
//

import Foundation
//import Network
import ArgumentParser
import SwiftSnmpKit

@main
struct SwiftSnmpV3Get: AsyncParsableCommand {
    // ./swiftsnmpv3get -c public 192.168.4.120 1.3.6.1.2.1.1.1.0
    static let version = "0.0.2"
    static let commandName = "swiftsnmpv3get"
    static let discussion = """
    SNMP commands in native Swift and open-source!
    https://github.com/darrellroot/SwiftSnmpKit
    """
    static let configuration = CommandConfiguration(commandName: commandName, abstract: "", usage: "\(commandName) [OPTIONS] AGENT OID", discussion: discussion, version: version, shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    @Argument(help: "SNMP engine-id") var engineId: String = "80000009034c710c19e30d"
    @Argument(help: "SNMP username") var username: String = "ciscoauth" // ciscouser
    @Argument(help: "SNMP agent IP or hostname") var agent: String = "192.168.4.120"
    @Argument(help: "SNMP OID") var oid: String = "1.3.6.1.2.1.1.1.0"
    
    func run() async {
        guard let snmpOid = SnmpOid(oid) else {
            fatalError("Invalid OID")
        }
        guard let snmpSender = SnmpSender.shared else {
            fatalError("Snmp Sender not inialized")
        }
        guard let snmpOid = SnmpOid(oid) else {
            fatalError("Invalid OID: \(oid)")
        }
        //let result = await snmpSender.sendV3(host: agent, engineId: engineId, userName: username, pduType: .getRequest, oid: snmpOid)
        for _ in 0..<3 {
            let result = await snmpSender.sendV3(host: agent, userName: username, pduType: .getRequest, oid: snmpOid, authenticationType: .sha1, password: "authkey1auth")
                
            switch result {
            case .failure(let error):
                print("SNMP Error: \(error.localizedDescription)")
            case .success(let variableBinding):
                print(variableBinding)
            }
            sleep(1)
        }
    }
}

