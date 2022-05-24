// osascript -e 'tell app "Finder" to quit'
// clang -fmodules -dynamiclib -I ../../non-metal-common/Utils blurtest5.m -F /System/Library/PrivateFrameworks -framework SkyLight -o /tmp/b.dylib -Wno-unused-getter-return-value && codesign -f -s - /tmp/b.dylib && DYLD_INSERT_LIBRARIES=/tmp/b.dylib /S*/L*/C*/F*/C*/M*/Finder

#import "Utils.h"
@import AppKit;
@import Darwin.POSIX.dlfcn;

extern id kCAProxyLayerMaterial;
extern id kCAProxyLayerBlendMode;
extern id kCAProxyLayerActive;
extern id kCAProxyLayerSaturation;
extern id kCAProxyLayerSelectionTintColor;
extern id kCAProxyLayerLevel;
extern id kCAFilterClear;
extern id kCAFilterCopy;
extern id kCAFilterSourceOver;
extern id kCAFilterSourceIn;
extern id kCAFilterSourceOut;
extern id kCAFilterSourceAtop;
extern id kCAFilterDest;
extern id kCAFilterDestOver;
extern id kCAFilterDestIn;
extern id kCAFilterDestOut;
extern id kCAFilterDestAtop;
extern id kCAFilterXor;
extern id kCAFilterPlusL;
extern id kCAFilterSubtractS;
extern id kCAFilterSubtractD;
extern id kCAFilterMultiply;
extern id kCAFilterMinimum;
extern id kCAFilterMaximum;
extern id kCAFilterPlusD;
extern id kCAFilterNormalBlendMode;
extern id kCAFilterMultiplyBlendMode;
extern id kCAFilterScreenBlendMode;
extern id kCAFilterOverlayBlendMode;
extern id kCAFilterDarkenBlendMode;
extern id kCAFilterLightenBlendMode;
extern id kCAFilterColorDodgeBlendMode;
extern id kCAFilterColorBurnBlendMode;
extern id kCAFilterSoftLightBlendMode;
extern id kCAFilterHardLightBlendMode;
extern id kCAFilterDifferenceBlendMode;
extern id kCAFilterExclusionBlendMode;
extern id kCAFilterSubtractBlendMode;
extern id kCAFilterDivideBlendMode;
extern id kCAFilterLinearBurnBlendMode;
extern id kCAFilterLinearDodgeBlendMode;
extern id kCAFilterLinearLightBlendMode;
extern id kCAFilterPinLightBlendMode;
extern id kCAFilterVibrantLight;
extern id kCAFilterVibrantDark;

@interface CALayer(Private)
-(void)setAllowsGroupBlending:(BOOL)edx;
@end

@interface CAProxyLayer:CALayer
-(void)setProxyProperties:(NSDictionary*)rdx;
@end

@interface CAFilter:NSObject
+(instancetype)filterWithType:(id)rdx;
-(NSString*)name;
@end

BOOL SLSGetAppearanceThemeLegacy();

@interface NSVisualEffectView(Private)
-(BOOL)_shouldUseActiveAppearance;
@end

// blacklisting/materials here - Amy

#define SATURATION @2.7

NSString* materialForView(NSVisualEffectView* view)
{
	// within window blending
	
	if(view.blendingMode!=NSVisualEffectBlendingModeBehindWindow)
	{
		return nil;
	}
	
	// inactive
	
	if(!view._shouldUseActiveAppearance)
	{
		return nil;
	}
	
	// material-based logic
	// TODO: these all need to be re-checked and documented what they are
	
	BOOL dark=SLSGetAppearanceThemeLegacy();
	switch(view.material)
	{
		// blacklist - uses stock
		
		case 30:
		case 12:
		case 18:
		case 11:
		case 35:
		case NSVisualEffectMaterialSelection:
		case 36:
			return nil;
		
		// mapping - uses SL materials
		
		case NSVisualEffectMaterialMenu:
		case NSVisualEffectMaterialPopover:
		case 24: // menubar menu
			return dark?@"ThickDark":@"ThickLight";
		
		case NSVisualEffectMaterialSidebar:
		case NSVisualEffectMaterialUnderWindowBackground:
		case NSVisualEffectMaterialToolTip:
		case 19: // Spotlight
		case 31: // password windows
		case 33: // password windows again?
		case 0: // Hopper
			return dark?@"UltrathickDark":@"UltrathickLight";
		
		case NSVisualEffectMaterialHUDWindow:
		case 26: // HUD background
			return dark?@"ThinDark":@"ThinLight";
	}
	
	trace(@"unimplemented material %d",view.material);
	return nil;
}

@interface Proxy:CALayer

@property(assign) CAProxyLayer* proxy;

@end

@implementation Proxy

-(instancetype)init
{
	self=super.init;
	self.compositingFilter=[CAFilter filterWithType:kCAFilterCopy];
	
	_proxy=CAProxyLayer.layer;
	_proxy.compositingFilter=[CAFilter filterWithType:kCAFilterCopy];
	_proxy.frame=CGRectMake(-0x80000,-0x80000,0x100000,0x100000);
	
	[self addSublayer:_proxy];
	
	self.borderWidth=1;
	self.masksToBounds=true;
	
	return self;
}

// TODO: some severely fucked up shit
-(NSArray*)sublayers
{
	return @[];
}

@end

Proxy* findOrAddProxy(CALayer* parent,CALayer* relative,BOOL delayed)
{
	int relativeIndex=0;
	for(int i=0;i<parent.sublayers.count;i++)
	{
		CALayer* child=parent.sublayers[i];
		
		if([child isKindOfClass:Proxy.class])
		{
			return child;
		}
		
		if(child==relative)
		{
			relativeIndex=i;
		}
	}
	
	Proxy* proxy=Proxy.alloc.init;
	
	if(delayed)
	{
		dispatch_async(dispatch_get_main_queue(),^()
		{
			[parent insertSublayer:proxy atIndex:relativeIndex];
			proxy.release;
		});
	}
	else
	{
		[parent insertSublayer:proxy atIndex:relativeIndex];
		proxy.release;
	}
	
	return proxy;
}

void updateMimicProxy(CALayer* layer,BOOL active,NSString* mode)
{
	Proxy* wrapper=findOrAddProxy(layer.superlayer,layer,true);
		
	if(!active)
	{
		wrapper.hidden=true;
		return;
	}
	
	wrapper.hidden=false;
	wrapper.frame=layer.frame;
	
	wrapper.borderColor=NSColor.redColor.CGColor;
	
	NSMutableDictionary* props=NSMutableDictionary.alloc.init.autorelease;
	props[kCAProxyLayerMaterial]=@"Mimic";
	props[kCAProxyLayerActive]=@true;
	props[kCAProxyLayerBlendMode]=mode;
	props[kCAProxyLayerLevel]=@2;
	wrapper.proxy.proxyProperties=props;
}

// custom blending "fixes" here - Amy
// TODO: inefficient and just all around terrible

void checkBlendHacks(CALayer* layer,BOOL active)
{
	NSString* filterName=[layer.compositingFilter name];
	BOOL PD=[filterName isEqual:@"plusD"];
	BOOL PL=[filterName isEqual:@"plusL"];
	
	if(!PD&&!PL)
	{
		return;
	}
	
	if([NSStringFromClass(layer.class) isEqual:@"NSTextLayer"])
	{
		updateMimicProxy(layer,active,PD?@"PlusD":@"PlusL");
		return;
	}
}

#define MAX_DEPTH 10

void recurseLayer(CALayer* layer,int depth,BOOL active)
{
	NSString* pad=[@"" stringByPaddingToLength:depth*2 withString:@" " startingAtIndex:0];
	trace(@"%@%@ %@ %@",pad,layer,layer.name,NSStringFromClass(layer.class));
	
	checkBlendHacks(layer,active);
	
	if(depth==MAX_DEPTH)
	{
		return;
	}
	
	for(CALayer* child in layer.sublayers)
	{
		recurseLayer(child,depth+1,active);
	}
}

void (*real_updateLayer)(NSVisualEffectView*,SEL);
void fake_updateLayer(NSVisualEffectView* self,SEL sel)
{
	real_updateLayer(self,sel);
	
	Proxy* wrapper=findOrAddProxy(self.layer,self.subviews.firstObject.layer,false);
	CGRect frame=self.frame;
	frame.origin=CGPointZero;
	wrapper.frame=frame;
	
	wrapper.borderColor=NSColor.greenColor.CGColor;
	
	NSString* material=materialForView(self);

	if(material)
	{
		wrapper.hidden=false;
		
		NSMutableDictionary* props=NSMutableDictionary.alloc.init.autorelease;
		props[kCAProxyLayerMaterial]=material;
		props[kCAProxyLayerActive]=@true;
		props[kCAProxyLayerBlendMode]=@"S";
		props[kCAProxyLayerSaturation]=SATURATION;
		props[kCAProxyLayerLevel]=@1;
		wrapper.proxy.proxyProperties=props;
	}
	else
	{
		wrapper.hidden=true;
	}
	
	recurseLayer(self.layer,0,!!material);
}

__attribute__((constructor))
void load()
{
	swizzleImp(@"NSVisualEffectView",@"updateLayer",true,(IMP)fake_updateLayer,(IMP*)&real_updateLayer);
}