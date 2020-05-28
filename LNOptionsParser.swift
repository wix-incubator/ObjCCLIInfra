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

public func LNUsagePrintMessageAndExit(prependMessage: String?, logLevel: LNLogLevel) -> Never {
	LNUsagePrintMessageAndExit(prependMessage: prependMessage, logLevel: logLevel, exitCode: logLevel == .error ? -1 : 0)
}

public func LNUsagePrintMessageAndExit(prependMessage: String?, logLevel: LNLogLevel, exitCode: Int32) -> Never {
	LNUsagePrintMessage(prependMessage: prependMessage, logLevel: logLevel)
	exit(exitCode)
}
