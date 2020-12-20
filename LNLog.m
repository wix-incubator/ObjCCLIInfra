//
//  LNLog.m
//  ObjCCLIInfra
//
//  Created by Leo Natan (Wix) on 13/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "LNLog.h"
#import "DTXLogging.h"

DTX_CREATE_LOG(CLI)

void LNLog(LNLogLevel logLevel, NSString* format, ...)
{
	@autoreleasepool
	{
		static NSDictionary* logToLogMapping;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			logToLogMapping = @{@(LNLogLevelInfo): @(OS_LOG_TYPE_INFO), @(LNLogLevelDebug): @(OS_LOG_TYPE_DEBUG), @(LNLogLevelWarning): @(OS_LOG_TYPE_ERROR), @(LNLogLevelError): @(OS_LOG_TYPE_ERROR)};
		});
		
		FILE* selectedOutputHandle = logLevel == LNLogLevelStdOut ? stdout : stderr;
		
		NSString* message;
		@autoreleasepool
		{
			va_list argumentList;
			va_start(argumentList, format);
			message = [[NSString alloc] initWithFormat:format arguments:argumentList];
			va_end(argumentList);
		}
		
		if(logLevel >= LNLogLevelWarning)
		{
			@autoreleasepool
			{
				fprintf(selectedOutputHandle, "%s\n", message.UTF8String);
			}
		}
		
		NSNumber* osLogType = logToLogMapping[@(logLevel)];
		if(osLogType)
		{
			__dtx_log(__prepare_and_return_file_log(), osLogType.unsignedIntegerValue, @"", @"%@", message);
		}
	}
}
