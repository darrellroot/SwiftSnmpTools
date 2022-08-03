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
struct SwiftSnmpWalk: AsyncParsableCommand {
    // ./swiftsnmpwalk -c public 192.168.4.120 1.3.6.1.2.1.1.1.0
    
    // Near end of MIB 1.3.111.2.802.3.1.5.1.2.2.1.14.7
    
    static let version = "0.0.2"
    static let commandName = "swiftsnmpwalk"
    static let discussion = """
    SNMP commands in native Swift and open-source!
    https://github.com/darrellroot/SwiftSnmpKit
    """
    static let configuration = CommandConfiguration(commandName: commandName, abstract: "", usage: "\(commandName) [OPTIONS] AGENT OID", discussion: discussion, version: version, shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    @Option(name: .short, help: "SNMP community") var community: String = "public"
    @Argument(help: "SNMP agent IP or hostname") var agent: String = "192.168.4.120"
    //@Argument(help: "SNMP OID") var oid: String = "1.3.6.1.2.1.1.1.0"
    @Argument(help: "SNMP OID") var oid: String = "1.3.6.1.2"
    // near end of mib on my test box
    //@Argument(help: "SNMP OID") var oid: String = "1.3.111.2.802.3.1.5.1.2.2.1.13"
    
    func run() async {
        guard let snmpOid = SnmpOid(oid) else {
            fatalError("Invalid OID")
        }
        guard let snmpSender = SnmpSender.shared else {
            fatalError("Snmp Sender not inialized")
        }
        var done = false
        // three or more consecutive failures with our get or getNext requests terminates the loop
        var consecutiveNextFailures = 0
        var nextOid = snmpOid
        while(!done) {
            //let getNextResult = await snmpSender.send(host: agent,command: .getNextRequest, community: community,oid: nextOid.description)
            let getNextResult = await snmpSender.send(host: agent, userName: "ciscoprivuser", pduType: .getNextRequest, oid: nextOid.description, authenticationType: .sha1, authPassword: "authpassword", privPassword: "privpassword")

            switch getNextResult {
            case .failure(let error):
                consecutiveNextFailures += 1
                print("SNMP Error: \(error.localizedDescription)")
            case .success(let variableBinding):
                print(variableBinding)
                if variableBinding.value == AsnValue.endOfMibView {
                    done = true
                }
                if variableBinding.value == AsnValue.noSuchObject {
                    consecutiveNextFailures += 1
                } else {
                    consecutiveNextFailures = 0
                }
                nextOid = variableBinding.oid
            }

            if consecutiveNextFailures > 2 {
                done = true
            }
        }
    }
}

