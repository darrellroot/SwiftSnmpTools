//
//  main.swift
//  swiftsnmpget
//
//  Created by Darrell Root on 7/2/22.
//

import Foundation
//import Network
import ArgumentParser
import SwiftSnmpKit

@main
struct SwiftSnmpV2Get: AsyncParsableCommand {
    // ./swiftsnmpv2get -c public 192.168.4.120 1.3.6.1.2.1.1.1.0
    static let version = "0.1.0"
    static let commandName = "swiftsnmpv2get"
    static let discussion = """
    SNMP commands in native Swift and open-source!
    https://github.com/darrellroot/SwiftSnmpKit
    """
    static let configuration = CommandConfiguration(commandName: commandName, abstract: "", usage: "\(commandName) [OPTIONS] AGENT OID", discussion: discussion, version: version, shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    @Option(name: .short, help: "SNMP community") var community: String = "public"
    // I include a default agent just to assist with development
    @Argument(help: "SNMP agent IP or hostname") var agent: String = "192.168.4.120"
    @Argument(help: "SNMP OID") var oid: String = "1.3.6.1.2.1.1.1.0"
    
    func run() async {
        guard let _ = SnmpOid(oid) else {
            fatalError("Invalid OID")
        }
        guard let snmpSender = SnmpSender.shared else {
            fatalError("Snmp Sender not inialized")
        }
        
        let result = await snmpSender.send(host: agent,command: .getRequest, community: community,oid: oid)
            
        switch result {
        case .failure(let error):
            print("SNMP Error: \(error.localizedDescription)")
        case .success(let variableBinding):
            print(variableBinding)
        }
    }
}

