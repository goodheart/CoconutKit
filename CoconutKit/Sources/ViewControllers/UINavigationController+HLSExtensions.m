//
//  UINavigationController+HLSExtensions.m
//  CoconutKit
//
//  Created by Samuel Défago on 10/16/12.
//  Copyright (c) 2012 Samuel Défago. All rights reserved.
//

#import "UINavigationController+HLSExtensions.h"

#import "HLSRuntime.h"

// Associated object keys
static void *s_autorotationModeKey = &s_autorotationModeKey;

// Original implementation of the methods we swizzle
static BOOL (*s_shouldAutorotate)(id, SEL) = NULL;
static NSUInteger (*s_supportedInterfaceOrientations)(id, SEL) = NULL;

// Swizzled method implementations
static BOOL swizzle_shouldAutorotate(UINavigationController *self, SEL _cmd);
static NSUInteger swizzle_supportedInterfaceOrientations(UINavigationController *self, SEL _cmd);

@implementation UINavigationController (HLSExtensions)

#pragma mark Class methods

+ (void)load
{
    s_shouldAutorotate = (__typeof(s_shouldAutorotate))hls_class_swizzleSelector(self, @selector(shouldAutorotate), (IMP)swizzle_shouldAutorotate);
    s_supportedInterfaceOrientations = (__typeof(s_supportedInterfaceOrientations))hls_class_swizzleSelector(self,
                                                                                                             @selector(supportedInterfaceOrientations),
                                                                                                             (IMP)swizzle_supportedInterfaceOrientations);
}

#pragma mark Accessors and mutators

- (HLSAutorotationMode)autorotationMode
{
    NSNumber *autorotationModeNumber = hls_getAssociatedObject(self, s_autorotationModeKey);
    if (! autorotationModeNumber) {
        return HLSAutorotationModeContainer;
    }
    else {
        return [autorotationModeNumber integerValue];
    }
}

- (void)setAutorotationMode:(HLSAutorotationMode)autorotationMode
{
    hls_setAssociatedObject(self, s_autorotationModeKey, @(autorotationMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

static BOOL swizzle_shouldAutorotate(UINavigationController *self, SEL _cmd)
{
    // The container always decides first (does not look at children)
    if (! (*s_shouldAutorotate)(self, _cmd)) {
        return NO;
    }
    
    switch (self.autorotationMode) {
        case HLSAutorotationModeContainerAndAllChildren: {
            for (UIViewController *viewController in [self.viewControllers reverseObjectEnumerator]) {
                if (! [viewController shouldAutorotate]) {
                    return NO;
                }
            }
            break;
        }
            
        case HLSAutorotationModeContainerAndTopChildren: {
            if (! [self.topViewController shouldAutorotate]) {
                return NO;
            }
            break;
        }
            
        case HLSAutorotationModeContainerAndNoChildren:
        case HLSAutorotationModeContainer:
        default: {
            break;
        }
    }
    
    return YES;
}

static NSUInteger swizzle_supportedInterfaceOrientations(UINavigationController *self, SEL _cmd)
{
    // The container always decides first (does not look at children)
    NSUInteger containerSupportedInterfaceOrientations = (*s_supportedInterfaceOrientations)(self, _cmd);
    
    switch (self.autorotationMode) {
        case HLSAutorotationModeContainerAndAllChildren: {
            for (UIViewController *viewController in [self.viewControllers reverseObjectEnumerator]) {
                containerSupportedInterfaceOrientations &= [viewController supportedInterfaceOrientations];
            }
            break;
        }
            
        case HLSAutorotationModeContainerAndTopChildren: {
            containerSupportedInterfaceOrientations &= [self.topViewController supportedInterfaceOrientations];
            break;
        }
            
        case HLSAutorotationModeContainerAndNoChildren:
        case HLSAutorotationModeContainer:
        default: {
            break;
        }
    }
    
    return containerSupportedInterfaceOrientations;
}
