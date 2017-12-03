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

@end

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
	__usageOptions = [usageOptions copy];
}

void LNUsageSetHiddenOptions(NSArray<LNUsageOption*>* __nullable hiddenUsageOptions)
{
	__hiddenUsageOptions = [hiddenUsageOptions copy];
}

void LNUsageSetAdditionalTopics(NSArray<NSDictionary<NSString*, NSArray*>*>* additionalTopics)
{
	__additionalTopics = [additionalTopics copy];
}

void LNUsageSetAdditionalStrings(NSArray<NSString*>* additionalStrings)
{
	__additionalStrings = [additionalStrings copy];
}

void LNUsagePrintMessage(NSString* prependMessage, LNLogLevel logLevel)
{
	NSString* utilName = NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent;
	
	if(prependMessage.length > 0)
	{
		LNLog(logLevel, @"%@\n", prependMessage);
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
		LNLog(LNLogLevelStdOut, @"Usage:");
		[__usageStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"    %@", obj], utilName);
		}];
		LNLog(LNLogLevelStdOut, @"");
	}
	
	__block NSUInteger longestOptionLength = 0;
	[__usageOptions enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* optionString = obj.shortcut != nil ? [NSString stringWithFormat:@"--%@, -%@", obj.name, obj.shortcut] : [NSString stringWithFormat:@"--%@", obj.name];
		longestOptionLength = optionString.length > longestOptionLength ? optionString.length : longestOptionLength;
	}];
	
	NSArray* options = [__usageOptions arrayByAddingObject:[LNUsageOption optionWithName:@"help" shortcut:@"h" valueRequirement:GBValueNone description:@"Prints usage"]];
	LNLog(LNLogLevelStdOut, @"Options:");
	[options enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* optionString = obj.shortcut != nil ? [NSString stringWithFormat:@"--%@, -%@", obj.name, obj.shortcut] : [NSString stringWithFormat:@"--%@", obj.name];
		LNLog(LNLogLevelStdOut, [NSString stringWithFormat:@"    %@%@", [optionString stringByPaddingToLength:longestOptionLength + 3 withString:@" " startingAtIndex:0], obj.description], utilName);
	}];
	LNLog(LNLogLevelStdOut, @"");
	
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

GBSettings* LNUsageParseArguments(int argc, const char* __nonnull * __nonnull argv)
{
	GBCommandLineParser *parser = [GBCommandLineParser new];
	
	NSArray<LNUsageOption*>* options = [__usageOptions arrayByAddingObject:[LNUsageOption optionWithName:@"help" shortcut:@"h" valueRequirement:GBValueNone description:@"Prints usage"]];
	[options enumerateObjectsUsingBlock:^(LNUsageOption*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[parser registerOption:obj.name shortcut:[obj.shortcut characterAtIndex:0] requirement:obj.valueRequirement];
	}];
	
	[__hiddenUsageOptions enumerateObjectsUsingBlock:^(LNUsageOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[parser registerOption:obj.name shortcut:[obj.shortcut characterAtIndex:0] requirement:obj.valueRequirement];
	}];
	
	GBSettings *settings = [GBSettings settingsWithName:@"CLI" parent:nil];
	
	[parser registerSettings:settings];
	[parser parseOptionsWithArguments:(char**)argv count:argc];
	
	if([settings boolForKey:@"help"])
	{
		LNUsagePrintMessage(nil, LNLogLevelStdOut);
		exit(0);
	}
	
	return settings;
}


