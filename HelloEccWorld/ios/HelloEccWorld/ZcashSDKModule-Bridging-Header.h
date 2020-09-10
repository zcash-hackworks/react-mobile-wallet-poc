//
//  ZcashSDKModule-Bridging-Header.h
//  HelloEccWorld
//
//  Created by Francisco Gindre on 9/9/20.
//



#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "AppDelegate.h"

@interface RCT_EXTERN_MODULE(ZcashReactSdk, RCTEventEmitter)
RCT_EXTERN_METHOD(initialize:(NSString*) vk birthday:(NSInteger)birthday resolve:(RCTPromiseResolveBlock)resolveBlock reject:(RCTPromiseRejectBlock)rejectBlock)
RCT_EXTERN_METHOD(show:(NSString*)message)
@end


