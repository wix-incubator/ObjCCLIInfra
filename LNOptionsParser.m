//
//  LNOptionsParser.m
//  ObjCCLIInfra
//
//  Created by Leo Natan (Wix) on 11/26/17.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "LNOptionsParser.h"
#import "GBCli.h"

static NSString* prefixString = @"    ";

static NSArray<NSString*>* __introStrings;
static NSArray<NSString*>* __usageStrings;
static NSArray<LNUsageOption*>* __usageOptions;
static NSArray<LNUsageOption*>* __hiddenUsageOptions;
static NSArray<NSDictionary<NSString*, NSArray*>*>* __additionalTopics;
static NSArray<NSString*>* __additionalStrings;
static NSString* __utilName;

@interface _LNEmptyOption : LNUsageOption @end

@interface LNUsageOption ()

@property (nonatomic, copy, readwrite) NSString* name;
@property (nonatomic, copy, readwrite) NSString* shortcut;
@property (nonatomic, readwrite) LNUsageOptionRequirement valueRequirement;
@property (nonatomic, copy, readwrite) NSString* description;

@end

@implementation LNUsageOption

@synthesize description=_description;

+ (instancetype)optionWithName:(NSString *)name valueRequirement:(LNUsageOptionRequirement)valueRequirement description:(NSString *)description
{
	return [self optionWithName:name shortcut:nil valueRequirement:valueRequirement description:description];
}

+ (instancetype)optionWithName:(NSString*)name shortcut:(nullable NSString*)shortcut valueRequirement:(LNUsageOptionRequirement)valueRequirement description:(NSString*)description
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
	LNUsageSetUtilName(nil);
}

void LNUsageSetUtilName(NSString* name)
{
	__utilName = name ?: NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent;
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
	[options addObject:[LNUsageOption optionWithName:@"help" shortcut:@"h" valueRequirement:LNUsageOptionRequirementNone description:@"Prints usage"]];
	
	__usageOptions = options;
}

void LNUsageSetHiddenOptions(NSArray<LNUsageOption*>* __nullable hiddenUsageOptions)
{
	NSMutableArray* options = hiddenUsageOptions.mutableCopy;
	if(options == nil)
	{
		options = [NSMutableArray new];
	}
	[options addObject:[LNUsageOption optionWithName:@"help2" valueRequirement:LNUsageOptionRequirementNone description:@"Prints advanced or deprecated usage"]];
	
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

static void _LNPrintOptionsArray(NSString* title, NSArray<LNUsageOption*>* usageOptions, NSString* utilName, BOOL includeHiddenInLength)
{
	__block NSUInteger longestOptionLength = 0;
	
	NSArray<LNUsageOption*>* forLength = __usageOptions;
	if(includeHiddenInLength)
	{
		forLength = [forLength arrayByAddingObjectsFromArray:__hiddenUsageOptions];
	}
	
	[forLength enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.name == nil) { return; }
		NSUInteger currentLength = [NSString stringWithFormat:@"--%@%@", obj.name, obj.shortcut ? [NSString stringWithFormat:@", -%@", obj.shortcut] : @""].length;
		longestOptionLength = currentLength > longestOptionLength ? currentLength : longestOptionLength;
	}];
	
	LNLog(LNLogLevelStdOut, @"%@:", title);
	[usageOptions enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:_LNEmptyOption.class])
		{
			LNLog(LNLogLevelStdOut, @"");
			return;
		}
		
		NSUInteger prefix = longestOptionLength;
		
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
	if(prependMessage.length > 0)
	{
		if(logLevel == LNLogLevelError)
		{
			prependMessage = [NSString stringWithFormat:@"%@ %@", prependMessage, [NSString stringWithFormat:@"See “%@ --help” for usage.", __utilName]];
		}
		LNLog(logLevel, @"%@", prependMessage);
		
		
		return;
	}
	
	if(__introStrings.count > 0)
	{
		[__introStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, obj, __utilName);
		}];
		LNLog(LNLogLevelStdOut, @"");
	}
	
	if(__usageStrings.count > 0)
	{
		LNLog(LNLogLevelStdOut, @"Usage Examples:");
		[__usageStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"%@%@", prefixString, obj], __utilName);
		}];
		LNLog(LNLogLevelStdOut, @"");
	}
	
	_LNPrintOptionsArray(@"Options", __usageOptions, __utilName, printHidden);
	
	if(printHidden)
	{
		_LNPrintOptionsArray(@"Advanced or Deprecated Options", __hiddenUsageOptions, __utilName, YES);
	}
	
	if(__additionalTopics.count > 0)
	{
		[__additionalTopics enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSArray *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSString* title = obj.allKeys.firstObject;
			NSArray<NSString*>* strings = obj[title];
			LNLog(LNLogLevelStdOut, @"%@:", title);
			[strings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"%@%@", prefixString, obj], __utilName);
			}];
			LNLog(LNLogLevelStdOut, @"");
		}];
	}
	
	if(__additionalStrings.count > 0)
	{
		[__additionalStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, obj, __utilName);
		}];
	}
}

void LNUsagePrintMessage(NSString* __nullable prependMessage, LNLogLevel logLevel)
{
	_LNUsagePrintMessage(prependMessage, logLevel, NO);
}

id<LNUsageArgumentParser> LNUsageParseArguments(int argc, const char* __nonnull * __nonnull argv)
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
	
	return (id)settings;
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
