//
//  main.swift
//  NioGetTest
//
//  Created by Darrell Root on 7/12/22.
//

import Foundation
import NIOCore
import NIOPosix
import SwiftSnmpKit

print("Hello, World!")

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try! group.syncShutdownGracefully()
}

let server = try! DatagramBootstrap(group: group)
    .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .bind(host: "0.0.0.0", port: 0).wait()
print("bound to \(server.localAddress)")

let snmpMessage = SnmpMessage(community: "public", command: .getRequest, oid: SnmpOid("1.3.6.1.2.1.1.1.0")!)
var buffer = server.allocator.buffer(bytes: snmpMessage.asnData)

let envelope = AddressedEnvelope(remoteAddress: try! SocketAddress(ipAddress: "192.168.4.120", port: 161), data: buffer)
let result = server.writeAndFlush(envelope)

try server.closeFuture.wait()
