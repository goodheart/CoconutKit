//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Helper header file for defining new notifications.
 *
 * A module introducing new notifications should:
 *   1) in its header file, declare the new notification name using the HLSDeclareNotification macro
 *   2) in its implementation file, define the new notification using the HLSDefineNotification macro
 * If two modules try to introduce the same notification name, a linker error will occur (since the symbol 
 * is in this case multiply defined in two separate translation units). This is good expected behavior, and 
 * this matches the approach applied in the Apple frameworks (see e.g. NSWindow on MacOS, or UIWindow on iOS)
 *
 * Note that notification names should end with "Notification"
 */
#define HLSDeclareNotification(name)      extern NSString * const name
#define HLSDefineNotification(name)       NSString * const name = @#name

/**
 * Manages application-wide notification mechanisms
 *
 * This class is not thread-safe
 */
@interface HLSNotificationManager : NSObject

/**
 * Get the shared object managing application-wide notifications
 */
+ (instancetype)sharedNotificationManager;

/**
 * Create a notification manager
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Call this method to notify that a network task has started. This method can be called several times if several
 * tasks are running simultaneously (an activity indicator is displayed in the status bar when at least one task 
 * is running)
 */
- (void)notifyBeginNetworkActivity;

/**
 * Call this method to notify that a network task has ended. This method can be called several times if several
 * tasks are running simultaneously (an activity indicator is displayed in the status bar when at least one task 
 * is running)
 */
- (void)notifyEndNetworkActivity;

@end

/**
 * To avoid breaking encapsulation, an object composed from (retained) objects emitting notifications should translate
 * those notifications into its own notifications, otherwise the object internals might be revealed. Writing
 * such conversion code can be tedious and error prone. The HLSNotificationConverter singleton provides a convenient
 * way to define conversions with very litte code.
 */
@interface HLSNotificationConverter : NSObject

/**
 * Singleton instance
 */
+ (instancetype)sharedNotificationConverter;

/**
 * Create a notification converter
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Add a conversion rule. The objectFrom and objectTo objects are NOT retained, as for NSNotificationManager. This is 
 * not needed (and not desirable) since:
 *  - objectFrom: When deallocated, an object must have unregistered itself from the HLSNotificationConverter
 *                by calling removeConversionsFromObject:
 *  - objectTo: HLSNotificationConverter is meant to be used for converting notifications in object compositions,
 *              where objectFrom is a member of objectTo and is retained by it. As long as the conversion rule
 *              exists (and provided objectFrom removes all associated rules when it gets deallocated) objectTo
 *              is guaranteed to be valid, since its lifetime is longer than the one of objectFrom
 */
- (void)convertNotificationWithName:(NSString *)notificationNameFrom
                       sentByObject:(nullable id)objectFrom
           intoNotificationWithName:(NSString *)notificationNameTo
                       sentByObject:(nullable id)objectTo;

/**
 * Add a conversion rule for all objects within an enumerable collection. Convenience function with same semantics
 * as -convertNotificationWithName:sentByObject:intoNotificationWithName:sentByObject:
 */
- (void)convertNotificationWithName:(NSString *)notificationNameFrom
           sentByObjectInCollection:(nullable id<NSFastEnumeration>)collectionFrom
           intoNotificationWithName:(NSString *)notificationNameTo
                       sentByObject:(nullable id)objectTo;

/**
 * Remove all conversion rules related to an object
 */
- (void)removeConversionsFromObject:(nullable id)objectFrom;

/**
 * Remove all conversion rules related to all objects of an enumerable collection
 */
- (void)removeConversionsFromObjectsInCollection:(nullable id<NSFastEnumeration>)collectionFrom;

@end

/**
 * Extensions for writing less notification code in the most common cases
 */
@interface NSObject (HLSNotificationExtensions)

- (void)postCoalescingNotificationWithName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;
- (void)postCoalescingNotificationWithName:(NSString *)name;

@end

@interface NSNotificationCenter (HLSNotificationExtensions)

- (void)addObserver:(id)observer selector:(SEL)selector name:(nullable NSString *)name objectsInCollection:(nullable id<NSFastEnumeration>)collection;
- (void)removeObserver:(id)observer name:(nullable NSString *)name objectsInCollection:(nullable id<NSFastEnumeration>)collection;

@end

NS_ASSUME_NONNULL_END
