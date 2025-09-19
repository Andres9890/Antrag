//
//  LSApplicationWorkspace.h
//  Private Framework Headers for TrollStore
//

#import <Foundation/Foundation.h>

@class LSApplicationProxy;

@interface LSApplicationWorkspace : NSObject

+ (instancetype)defaultWorkspace;

// App enumeration
- (NSArray<LSApplicationProxy *> *)allApplications;
- (NSArray<LSApplicationProxy *> *)applicationsOfType:(NSUInteger)type;
- (NSArray<LSApplicationProxy *> *)allInstalledApplications;

// App management
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options error:(NSError **)error;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;
- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;

// App information
- (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier;

@end

// Application types
typedef NS_ENUM(NSUInteger, LSApplicationType) {
    LSApplicationTypeAny = 0,
    LSApplicationTypeUser = 1,
    LSApplicationTypeSystem = 2
};