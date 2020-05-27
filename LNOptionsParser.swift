//
//  LNOptionsParser.swift
//  DetoxRecorderCLI
//
//  Created by Leo Natan (Wix) on 5/27/20.
//  Copyright © 2020 Wix. All rights reserved.
//

import Foundation
import AppKit

public func LNUsageParseArguments() -> LNUsageArgumentParser {
	//Swift is a retarded language.
	return CommandLine.unsafeArgv.withMemoryRebound(to: UnsafePointer<Int8>.self, capacity: Int(CommandLine.argc)) { pointer -> LNUsageArgumentParser in
		return __LNUsageParseArguments(CommandLine.argc, pointer)
	}
}

public func LNUsagePrintMessageAndExit(prependMessage: String?, logLevel: LNLogLevel, exitCode: Int32 = -1) -> Never {
	LNUsagePrintMessage(prependMessage: prependMessage, logLevel: logLevel)
	exit(exitCode)
}
