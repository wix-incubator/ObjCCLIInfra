//
//  LNOptionsParser.h
//  ObjCCLIInfra
//
//  Created by Leo Natan (Wix) on 11/26/17.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LNLog.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LNUsageOptionRequirement) {
	LNUsageOptionRequirementRequired, ///< Command line argument requires a value.
	LNUsageOptionRequirementOptional, ///< Command line argument can optionally have a value, but is not required.
	LNUsageOptionRequirementNone ///< Command line argument is on/off switch.
};

@protocol LNUsageArgumentParser <NSObject>

- (nullable id)objectForKey:(NSString *)key;
- (void)setObject:(nullable id)value forKey:(NSString *)key;

- (BOOL)boolForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (NSInteger)integerForKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

- (NSUInteger)unsignedIntegerForKey:(NSString *)key;
- (void)setUnsignedInteger:(NSUInteger)value forKey:(NSString *)key;

- (CGFloat)floatForKey:(NSString *)key;
- (void)setFloat:(CGFloat)value forKey:(NSString *)key;

@end

@interface LNUsageOption : NSObject

@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, nullable, copy, readonly) NSString* shortcut;
@property (nonatomic, readonly) LNUsageOptionRequirement valueRequirement;
@property (nonatomic, copy, readonly) NSString* description;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)emptyOption;
+ (instancetype)optionWithName:(NSString*)name valueRequirement:(LNUsageOptionRequirement)valueRequirement description:(NSString*)description;
+ (instancetype)optionWithName:(NSString*)name shortcut:(nullable NSString*)shortcut valueRequirement:(LNUsageOptionRequirement)valueRequirement description:(NSString*)description;

@end

extern void LNUsageSetUtilName(NSString* __nullable name);

extern void LNUsageSetIntroStrings(NSArray<NSString*>* __nullable introStrings);
extern void LNUsageSetExampleStrings(NSArray<NSString*>* __nullable usageStrings);
extern void LNUsageSetOptions(NSArray<LNUsageOption*>* __nullable usageOptions);
extern void LNUsageSetHiddenOptions(NSArray<LNUsageOption*>* __nullable hiddenUsageOptions);
extern void LNUsageSetAdditionalTopics(NSArray<NSDictionary<NSString*, NSArray*>*>* __nullable additionalTopics);
extern void LNUsageSetAdditionalStrings(NSArray<NSString*>* __nullable additionalStrings);

extern void LNUsagePrintMessage(NSString* __nullable prependMessage, LNLogLevel logLevel) NS_SWIFT_NAME(LNUsagePrintMessage(prependMessage:logLevel:));

extern void LNUsagePrintArguments(LNLogLevel logLevel) NS_SWIFT_NAME(LNUsagePrintArguments(logLevel:));
extern id<LNUsageArgumentParser> LNUsageParseArguments(int argc, const char* __nonnull * __nonnull argv) NS_REFINED_FOR_SWIFT;

NS_ASSUME_NONNULL_END
