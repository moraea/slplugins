// clang -fmodules -dynamiclib -I /V*/F*/M*/U* DiskReveal.m -o DiskReveal.dylib
// codesign -f -s - DiskReveal.dylib

#import "Utils.h"

NSArray* fake_VD(id self,SEL sel)
{
	return [self allDisks];
}

BOOL fake_CSD(id self,SEL sel,id rdx)
{
	return true;
}

@interface Load:NSObject
@end

@implementation Load

+(void)load
{
	traceLog=true;
	tracePrint=false;
	
	swizzleImp(@"SKManager",@"visibleDisks",true,(IMP)fake_VD,NULL);
	swizzleImp(@"SUSidebarController",@"_canShowDisk:",true,(IMP)fake_CSD,NULL);
}

@end