//
//  LSApplicationProxy.h
//  Private Framework Headers for TrollStore
//

#import <Foundation/Foundation.h>

@interface LSApplicationProxy : NSObject

// Basic app information
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *bundleIdentifier;
@property (nonatomic, readonly) NSURL *bundleURL;
@property (nonatomic, readonly) NSURL *containerURL;
@property (nonatomic, readonly) NSString *bundleExecutable;
@property (nonatomic, readonly) NSString *bundleVersion;
@property (nonatomic, readonly) NSString *shortVersionString;

// Display information
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *localizedShortName;
@property (nonatomic, readonly) NSString *itemName;

// App metadata
@property (nonatomic, readonly) NSString *applicationType;
@property (nonatomic, readonly) NSString *signerIdentity;
@property (nonatomic, readonly) NSString *teamID;
@property (nonatomic, readonly) NSDictionary *entitlements;
@property (nonatomic, readonly) NSDictionary *infoPlist;

// App state
@property (nonatomic, readonly) BOOL isInstalled;
@property (nonatomic, readonly) BOOL isPlaceholder;
@property (nonatomic, readonly) BOOL isAppClip;
@property (nonatomic, readonly) BOOL isLaunchProhibited;

// Icon handling
- (NSURL *)bundleContainerURL;
- (NSData *)iconDataForVariant:(NSString *)variant;
- (NSData *)iconDataForVariant:(NSString *)variant withOptions:(NSDictionary *)options;

@end