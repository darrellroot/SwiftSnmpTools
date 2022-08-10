//
//  main.swift
//  swiftsnmpget
//
//  Created by Darrell Root on 7/2/22.
//

import Foundation
import ArgumentParser
import SwiftSnmpKit

@main
struct SwiftSnmpV3Walk: AsyncParsableCommand {
    // ./swiftsnmpv3walk -c public 192.168.4.120 1.3.6.1.2.1.1.1.0
    
    // Near end of MIB 1.3.111.2.802.3.1.5.1.2.2.1.14.7
    
    static let version = "0.0.2"
    static let commandName = "swiftsnmpv3walk"
    static let discussion = """
    SNMP commands in native Swift and open-source!
    https://github.com/darrellroot/SwiftSnmpKit
    This is currently hardcoded for SHA1 (if you provide an authentication username) and AES128 (if you provide a privacy username).
    """
    static let configuration = CommandConfiguration(commandName: commandName, abstract: "", usage: "\(commandName) [OPTIONS] AGENT OID", discussion: discussion, version: version, shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    @Option(name: .short, help: "username") var username: String
    @Option(name: .customShort("A"), help: "Authentication Password") var authPassword: String?
    @Option(name: .customShort("X"), help: "Privacy Password") var privPassword: String?
    
    // I set a default agent name to help development
    @Argument(help: "SNMP agent IP or hostname") var agent: String = "192.168.4.120"
    @Argument(help: "SNMP OID") var oid: String = "1.3.6.1.2"
    // near end of mib on my test box
    //@Argument(help: "SNMP OID") var oid: String = "1.3.111.2.802.3.1.5.1.2.2.1.13"
    
    func run() async {
        guard let snmpSender = SnmpSender.shared else {
            fatalError("Snmp Sender not inialized")
        }
        //SnmpSender.debug = true
        
        var done = false
        // three or more consecutive failures with our get or getNext requests terminates the loop
        var consecutiveNextFailures = 0
        // previously tested in validate()
        var nextOid = SnmpOid(oid)!
        var authType: SnmpV3Authentication
        if authPassword == nil {
            authType = .noAuth
        } else {
            authType = .sha1 // need a selector for this
        }
        while(!done) {
            //let getNextResult = await snmpSender.send(host: agent,command: .getNextRequest, community: community,oid: nextOid.description)
            let getNextResult = await snmpSender.send(host: agent, userName: username, pduType: .getNextRequest, oid: nextOid.description, authenticationType: authType, authPassword: authPassword, privPassword: privPassword)
            //let getNextResult = await snmpSender.send(host: agent, userName: "ciscoauth", pduType: .getNextRequest, oid: nextOid.description, authenticationType: .sha1, authPassword: "authkey1auth", privPassword: nil)
            //let getNextResult = await snmpSender.send(host: agent, userName: "ciscoprivuser", pduType: .getNextRequest, oid: nextOid.description, authenticationType: .sha1, authPassword: "authpassword", privPassword: "privpassword")

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
    mutating func validate() throws {
        guard let _ = SnmpOid(oid) else {
            throw ValidationError("Invalid SNMP OID")
        }
        if authPassword == nil && privPassword != nil {
            throw ValidationError("SNMPv3 Privacy requires SNMPv3 authentication")
        }
    }
}

