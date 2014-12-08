//
//  UISegmentedControl+HLSViewBinding.m
//  CoconutKit
//
//  Created by Samuel Défago on 29/03/14.
//  Copyright (c) 2014 Samuel Défago. All rights reserved.
//

#import "UISegmentedControl+HLSViewBinding.h"

#import "HLSRuntime.h"

// Original implementation of the methods we swizzle
static id (*s_initWithFrame)(id, SEL, CGRect) = NULL;
static id (*s_initWithCoder)(id, SEL, id) = NULL;
static void (*s_setSelectedSegmentIndex)(id, SEL, NSInteger) = NULL;

// Swizzled method implementations
static id swizzle_initWithFrame(UISegmentedControl *self, SEL _cmd, CGRect frame);
static id swizzle_initWithCoder(UISegmentedControl *self, SEL _cmd, NSCoder *aDecoder);
static void swizzle_setSelectedSegmentIndex(UISegmentedControl *self, SEL _cmd, NSInteger selectedSegmentIndex);

@implementation UISegmentedControl (HLSViewBindingImplementation)

#pragma mark Class methods

+ (void)load
{
    s_initWithFrame = (__typeof(s_initWithFrame))hls_class_swizzleSelector(self, @selector(initWithFrame:), (IMP)swizzle_initWithFrame);
    s_initWithCoder = (__typeof(s_initWithCoder))hls_class_swizzleSelector(self, @selector(initWithCoder:), (IMP)swizzle_initWithCoder);
    s_setSelectedSegmentIndex = (__typeof(s_setSelectedSegmentIndex))hls_class_swizzleSelector(self,
                                                                                               @selector(setSelectedSegmentIndex:),
                                                                                               (IMP)swizzle_setSelectedSegmentIndex);
    
}

#pragma mark HLSViewBindingImplementation protocol implementation

+ (NSArray *)supportedBindingClasses
{
    return @[[NSNumber class]];
}

- (void)updateViewWithValue:(id)value animated:(BOOL)animated
{
    self.selectedSegmentIndex = [value integerValue];
}

- (id)inputValueWithClass:(Class)inputClass
{
    return @(self.selectedSegmentIndex);
}

#pragma mark Actions

- (void)segmentDidChange:(id)sender
{
    [self check:YES update:YES withInputValue:@(self.selectedSegmentIndex) error:NULL];
}

@end

#pragma mark Static functions

// Neither -setOn:animated, nor -setOn: are called when the switch is changed interactively. To intercept those
// events, we need to add an action for UIControlEventValueChanged
static void commonInit(UISegmentedControl *self)
{
    [self addTarget:self action:@selector(segmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark Swizzled method implementations

static id swizzle_initWithFrame(UISegmentedControl *self, SEL _cmd, CGRect frame)
{
    if ((self = (*s_initWithFrame)(self, _cmd, frame))) {
        commonInit(self);
    }
    return self;

}

static id swizzle_initWithCoder(UISegmentedControl *self, SEL _cmd, NSCoder *aDecoder)
{
    if ((self = (*s_initWithCoder)(self, _cmd, aDecoder))) {
        commonInit(self);
    }
    return self;
}

static void swizzle_setSelectedSegmentIndex(UISegmentedControl *self, SEL _cmd, NSInteger selectedSegmentIndex)
{
    (*s_setSelectedSegmentIndex)(self, _cmd, selectedSegmentIndex);
    
    [self check:YES update:YES withInputValue:@(selectedSegmentIndex) error:NULL];
}
