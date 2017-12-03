//
//  LNOptionsParser.h
//  ObjCCLIInfra
//
//  Created by Leo Natan (Wix) on 11/26/17.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GBCli.h"
#import "LNLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface LNUsageOption : NSObject

@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, nullable, copy, readonly) NSString* shortcut;
@property (nonatomic, readonly) GBValueRequirements valueRequirement;
@property (nonatomic, copy, readonly) NSString* description;

+ (instancetype)optionWithName:(NSString*)name valueRequirement:(GBValueRequirements)valueRequirement description:(NSString*)description;
+ (instancetype)optionWithName:(NSString*)name shortcut:(nullable NSString*)shortcut valueRequirement:(GBValueRequirements)valueRequirement description:(NSString*)description;

@end

extern void LNUsageSetIntroStrings(NSArray<NSString*>* __nullable introStrings);
extern void LNUsageSetExampleStrings(NSArray<NSString*>* __nullable usageStrings);
extern void LNUsageSetOptions(NSArray<LNUsageOption*>* __nullable usageOptions);
extern void LNUsageSetHiddenOptions(NSArray<LNUsageOption*>* __nullable hiddenUsageOptions);
extern void LNUsageSetAdditionalTopics(NSArray<NSDictionary<NSString*, NSArray*>*>* __nullable additionalTopics);
extern void LNUsageSetAdditionalStrings(NSArray<NSString*>* __nullable additionalStrings);

extern void LNUsagePrintMessage(NSString* __nullable prependMessage, LNLogLevel logLevel);

extern GBSettings* LNUsageParseArguments(int argc, const char* __nonnull * __nonnull argv);

NS_ASSUME_NONNULL_END
