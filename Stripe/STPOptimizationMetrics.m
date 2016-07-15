//
//  STPOptimizationMetrics.m
//  Stripe
//
//  Created by Ben Guo on 7/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPOptimizationMetrics.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

NSString *const STPUserDefaultsKeyFirstAppOpenTime = @"STPFirstAppOpenTime";
NSString *const STPUserDefaultsKeyTotalAppOpenCount = @"STPTotalAppOpenCount";
NSString *const STPUserDefaultsKeyTotalAppUsageDuration = @"STPTotalAppUsageDuration";

@interface STPOptimizationMetrics ()
@property (nonatomic) NSMutableDictionary *events;
@end

@implementation STPOptimizationMetrics

+ (NSString *)eventNameWithClass:(Class)aClass suffix:(NSString *)suffix {
    NSString *className = NSStringFromClass(aClass);
    return [NSString stringWithFormat:@"%@_%@", className, suffix];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        _events = [NSMutableDictionary new];
        _smsAutofillUsed = NO;
    }
    return self;
}

- (NSDate *)firstAppOpenTime {
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:STPUserDefaultsKeyFirstAppOpenTime];
    if ([object isKindOfClass:[NSDate class]]) {
        return (NSDate *)object;
    }
    return nil;
}

- (NSNumber *)totalAppOpenCount {
    return @([[NSUserDefaults standardUserDefaults] integerForKey:STPUserDefaultsKeyTotalAppOpenCount]);
}

- (NSNumber *)totalAppUsageDuration {
    return @([[NSUserDefaults standardUserDefaults] integerForKey:STPUserDefaultsKeyTotalAppUsageDuration]);
}

- (void)logEvent:(NSString *)event {
    NSNumber *timestamp = [self timestampWithDate:[NSDate date]];
    NSArray *times = self.events[event];
    if (!times) {
        self.events[event] = @[timestamp];
    }
    else {
        self.events[event] = [times arrayByAddingObject:timestamp];
    }
}

- (NSNumber *)timestampWithDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    return @((NSInteger)[date timeIntervalSince1970]);
}

- (NSString *)stringForBatteryState:(UIDeviceBatteryState)state {
    switch (state) {
        case UIDeviceBatteryStateFull:
            return @"full";
        case UIDeviceBatteryStateCharging:
            return @"charging";
        case UIDeviceBatteryStateUnplugged:
            return @"unplugged";
        case UIDeviceBatteryStateUnknown:
            return @"unknown";
    }
}

- (NSDictionary *)serialize {
    NSMutableDictionary *payload = [NSMutableDictionary new];
    payload[@"first_app_open_time"] = [self timestampWithDate:[self firstAppOpenTime]];
    payload[@"total_app_open_count"] = [self totalAppOpenCount];
    payload[@"total_app_usage_duration"] = [self totalAppUsageDuration];
    payload[@"session_app_open_time"] = [self timestampWithDate:self.sessionAppOpenTime];
    payload[@"sms_autofill_used"] = @(self.smsAutofillUsed);
    payload[@"current_time"] = [self timestampWithDate:[NSDate date]];
    payload[@"events"] = self.events;
    UIDevice *device = [UIDevice currentDevice];
    NSString *version = device.systemVersion;
    if (version) {
        payload[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        payload[@"device_type"] = deviceType;
    }
    float batteryLevel = device.batteryLevel;
    if (batteryLevel > 0) {
        payload[@"battery_level"] = @(batteryLevel);
    }
    payload[@"battery_state"] = [self stringForBatteryState:device.batteryState];
    return payload;
}

@end
