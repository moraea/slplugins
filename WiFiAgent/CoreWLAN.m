#import "Utils.h"

id fake_UAWSJUFWN(id self,SEL sel,id rdx,id rcx,double xmm0,id (^r8)(id))
{
	trace(@"cw: fake_UAWSJUFWN");
	r8(nil);
	return nil;
}

id (*real_ROPWEH)(id self,SEL sel,id rdx);
id fake_ROPWEH(id self,SEL sel,id rdx)
{
	NSObject* result=real_ROPWEH(self,sel,rdx);
	
	if([NSStringFromClass(result.class) isEqualToString:@"__NSXPCInterfaceProxy_CWWiFiXPCRequestProtocol"])
	{
		trace(@"cw: fake_ROPWEH class_addMethod %d",class_addMethod(result.class,@selector(internal_userAgentWillShowJoinUIForWiFiNetwork:interfaceName:timestamp:reply:),(IMP)fake_UAWSJUFWN,"@@:@@@@"));
	}
	
	return result;
}

@interface Load:NSObject
@end

@implementation Load

+(void)load
{
	if([NSProcessInfo.processInfo.processName isEqualToString:@"WiFiAgent"])
	{
		traceLog=true;
		trace(@"cw: WiFiAgent");
		
		swizzleImp(@"NSXPCConnection",@"remoteObjectProxyWithErrorHandler:",true,(IMP)fake_ROPWEH,(IMP*)&real_ROPWEH);
	}
}

@end