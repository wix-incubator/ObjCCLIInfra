//
//  LNOptionsParser.m
//  ObjCCLIInfra
//
//  Created by Leo Natan (Wix) on 11/26/17.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "LNOptionsParser.h"

static NSArray<NSString*>* __introStrings;
static NSArray<NSString*>* __usageStrings;
static NSArray<LNUsageOption*>* __usageOptions;
static NSArray<LNUsageOption*>* __hiddenUsageOptions;
static NSArray<NSDictionary<NSString*, NSArray*>*>* __additionalTopics;
static NSArray<NSString*>* __additionalStrings;

@interface _LNEmptyOption : LNUsageOption @end

@interface LNUsageOption ()

@property (nonatomic, copy, readwrite) NSString* name;
@property (nonatomic, copy, readwrite) NSString* shortcut;
@property (nonatomic, readwrite) GBValueRequirements valueRequirement;
@property (nonatomic, copy, readwrite) NSString* description;

@end

@implementation LNUsageOption

@synthesize description=_description;

+ (instancetype)optionWithName:(NSString *)name valueRequirement:(GBValueRequirements)valueRequirement description:(NSString *)description
{
	return [self optionWithName:name shortcut:nil valueRequirement:valueRequirement description:description];
}

+ (instancetype)optionWithName:(NSString*)name shortcut:(nullable NSString*)shortcut valueRequirement:(GBValueRequirements)valueRequirement description:(NSString*)description
{
	LNUsageOption* rv = [LNUsageOption new];
	rv.name = name;
	rv.shortcut = shortcut;
	rv.valueRequirement = valueRequirement;
	rv.description = description;
	
	return rv;
}

+ (instancetype)emptyOption
{
	return [_LNEmptyOption new];
}

@end

@implementation _LNEmptyOption @end

__attribute__((constructor))
static void __LNUsageInit(void)
{
	LNUsageSetOptions(nil);
	LNUsageSetHiddenOptions(nil);
}

void LNUsageSetIntroStrings(NSArray<NSString*>* introStrings)
{
	__introStrings = [introStrings copy];
}

void LNUsageSetExampleStrings(NSArray<NSString*>* usageStrings)
{
	__usageStrings = [usageStrings copy];
}

void LNUsageSetOptions(NSArray<LNUsageOption*>* __nullable usageOptions)
{
	NSMutableArray* options = usageOptions.mutableCopy;
	if(options == nil)
	{
		options = [NSMutableArray new];
	}
	[options addObject:[LNUsageOption optionWithName:@"help" shortcut:@"h" valueRequirement:GBValueNone description:@"Prints usage"]];
	
	__usageOptions = options;
}

void LNUsageSetHiddenOptions(NSArray<LNUsageOption*>* __nullable hiddenUsageOptions)
{
	NSMutableArray* options = hiddenUsageOptions.mutableCopy;
	if(options == nil)
	{
		options = [NSMutableArray new];
	}
	[options addObject:[LNUsageOption optionWithName:@"help2" valueRequirement:GBValueNone description:@"Prints expanded usage"]];
	
	__hiddenUsageOptions = options;
}

void LNUsageSetAdditionalTopics(NSArray<NSDictionary<NSString*, NSArray*>*>* additionalTopics)
{
	__additionalTopics = [additionalTopics copy];
}

void LNUsageSetAdditionalStrings(NSArray<NSString*>* additionalStrings)
{
	__additionalStrings = [additionalStrings copy];
}

static void _LNPrintOptionsArray(NSArray<LNUsageOption*>* usageOptions, NSString* utilName)
{
	__block NSUInteger longestOptionLength = 0;
	__block NSUInteger longestShortcutLength = 0;
	
	[usageOptions enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		longestOptionLength = obj.name.length > longestOptionLength ? obj.name.length : longestOptionLength;
		longestShortcutLength = obj.shortcut.length > longestShortcutLength ? obj.shortcut.length : longestShortcutLength;
	}];
	
	LNLog(LNLogLevelStdOut, @"Options:");
	[usageOptions enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:_LNEmptyOption.class])
		{
			LNLog(LNLogLevelStdOut, @"");
			return;
		}
		
		NSUInteger prefix = longestOptionLength + longestShortcutLength + 5;
		NSString* prefixString = @"    ";
		
		NSMutableString* description = [NSMutableString new];
		[[obj.description componentsSeparatedByString:@"\n"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if(description.length > 0)
			{
				[description appendFormat:@"\n%@%@%@", prefixString, prefixString, [@"" stringByPaddingToLength:prefix withString:@" " startingAtIndex:0]];
			}
		
			[description appendString:obj];
		}];
		
		NSString* optionString = obj.shortcut != nil ? [NSString stringWithFormat:@"--%@, -%@", obj.name, obj.shortcut] : [NSString stringWithFormat:@"--%@", obj.name];
		LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"%@%@%@%@", prefixString, [optionString stringByPaddingToLength:prefix withString:@" " startingAtIndex:0], prefixString, description], utilName);
	}];
	LNLog(LNLogLevelStdOut, @"");
}

static void _LNUsagePrintMessage(NSString* prependMessage, LNLogLevel logLevel, BOOL printHidden)
{
	NSString* utilName = NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent;
	
	if(prependMessage.length > 0)
	{
		LNLog(logLevel, @"%@\n", prependMessage);
		
		if(logLevel >= LNLogLevelWarning)
		{
			LNLog(logLevel, @"%@", [NSString stringWithFormat:@"See '%@ --help'.", NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent]);
		}
		
		return;
	}
	
	if(__introStrings.count > 0)
	{
		[__introStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, obj, utilName);
		}];
		LNLog(LNLogLevelStdOut, @"");
	}
	
	if(__usageStrings.count > 0)
	{
		LNLog(LNLogLevelStdOut, @"Usage Examples:");
		[__usageStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"    %@", obj], utilName);
		}];
		LNLog(LNLogLevelStdOut, @"");
	}
	
	_LNPrintOptionsArray(__usageOptions, utilName);
	
	if(printHidden)
	{
		_LNPrintOptionsArray(__hiddenUsageOptions, utilName);
	}
	
	if(__additionalTopics.count > 0)
	{
		[__additionalTopics enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSArray *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSString* title = obj.allKeys.firstObject;
			NSArray<NSString*>* strings = obj[title];
			LNLog(LNLogLevelStdOut, @"%@:", title);
			[strings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"    %@", obj], utilName);
			}];
			LNLog(LNLogLevelStdOut, @"");
		}];
	}
	
	if(__additionalStrings.count > 0)
	{
		[__additionalStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, obj, utilName);
		}];
	}
}

void LNUsagePrintMessage(NSString* __nullable prependMessage, LNLogLevel logLevel)
{
	_LNUsagePrintMessage(prependMessage, logLevel, NO);
}

GBSettings* LNUsageParseArguments(int argc, const char* __nonnull * __nonnull argv)
{
	GBCommandLineParser *parser = [GBCommandLineParser new];
	
	[__usageOptions enumerateObjectsUsingBlock:^(LNUsageOption*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:_LNEmptyOption.class])
		{
			return;
		}
		
		[parser registerOption:obj.name shortcut:obj.shortcut requirement:obj.valueRequirement];
	}];
	
	[__hiddenUsageOptions enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[parser registerOption:obj.name shortcut:obj.shortcut requirement:obj.valueRequirement];
	}];
	
	GBSettings *settings = [GBSettings settingsWithName:@"CLI" parent:nil];
	
	[parser registerSettings:settings];
	[parser parseOptionsWithArguments:(char**)argv count:argc];
	
	if([settings boolForKey:@"help"])
	{
		_LNUsagePrintMessage(nil, LNLogLevelStdOut, NO);
		exit(0);
	}
	
	if([settings boolForKey:@"help2"])
	{
		_LNUsagePrintMessage(nil, LNLogLevelStdOut, YES);
		exit(0);
	}
	
	return settings;
}

void LNUsagePrintArguments(LNLogLevel logLevel)
{
	NSMutableArray* args = [NSMutableArray new];
	
	[NSProcessInfo.processInfo.arguments enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* format = @"%@";
		if([obj rangeOfCharacterFromSet:[NSCharacterSet.alphanumericCharacterSet invertedSet]].location != NSNotFound)
		{
			format = @"\"%@\"";
		}
		
		[args addObject:[NSString stringWithFormat:format, obj]];
	}];
	
	LNLog(logLevel, @"%@", [args componentsJoinedByString:@" "]);
}
