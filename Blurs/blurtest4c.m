// clang -fmodules -dynamiclib -I /Users/redacted/Desktop/HedgeSwizzle/Cracks/Utils/ blurtest4c.m -F /S*/L*/PrivateFrameworks -framework SkyLight -o /Library/Application\ Support/SkyLightPlugins/Blur.dylib

#import "Utils.h"
@import AppKit;

extern id kCAProxyLayerMaterial;
extern id kCAProxyLayerBlendMode;
extern id kCAProxyLayerActive;
extern id kCAProxyLayerSaturation;

extern id kCAFilterCopy;

@interface CAProxyLayer:CALayer
-(void)setProxyProperties:(NSDictionary*)rdx;
@end

@interface CAFilter:NSObject
@end


BOOL SLSGetAppearanceThemeLegacy();

void (*real_ul)(NSVisualEffectView* self,SEL sel);
void fake_ul(NSVisualEffectView* self,SEL sel)
{	
	
	if(self.blendingMode!=NSVisualEffectBlendingModeBehindWindow || self.material==30 || self.material==12 || self.material==18 || self.material==11 || self.material==35 | self.material==NSVisualEffectMaterialSelection || self.material==36)
	{
		// NSVisualEffectMaterialSheet=11, NSVisualEffectMaterialContentBackground=18, NSVisualEffectMaterialWindowBackground=12, window behind window blur=30;
		real_ul(self,sel);
		return;
	}
	
	CAProxyLayer* proxy=nil;
	
	for(CALayer* layer in self.layer.sublayers)
	{
		if([layer isKindOfClass:CAProxyLayer.class])
		{
			proxy=layer;
			break;
		}
	}
	
	if(!proxy)
	{
		proxy=CAProxyLayer.layer;
		[self.layer insertSublayer:proxy atIndex:0];
	}
	
	BOOL dark=SLSGetAppearanceThemeLegacy();
	NSString* material=nil;
	switch(self.material)
	{
		case 36: // context menu selection
			material=dark?@"FocusedDark":@"FocusedLight";
			break;
		case NSVisualEffectMaterialMenu:
		case NSVisualEffectMaterialPopover:
		case 24: // menubar menu
			material=dark?@"ThickDark":@"ThickLight";
			break;
		case NSVisualEffectMaterialSidebar:
		case NSVisualEffectMaterialUnderWindowBackground:
		case NSVisualEffectMaterialToolTip:
		case 19: // Spotlight
		case 31: // password windows
		case 33: // password windows again?
		case 0: // Hopper
			material=dark?@"UltrathickDark":@"UltrathickLight";
			break;
		case NSVisualEffectMaterialHUDWindow:
		case 26: // HUD background
			material=dark?@"ThinDark":@"ThinLight";
			break;
		default:
			trace(@"not implemented material %d for defenestrator 0.5",self.material);
			material=dark?@"UltrathinDark":@"UltrathinLight";
			return;
	}
			
	NSMutableDictionary* props=NSMutableDictionary.alloc.init.autorelease;
	props[kCAProxyLayerMaterial]=material;
	props[kCAProxyLayerActive]=@1;
	props[kCAProxyLayerBlendMode]=dark?@"PlusL":@"PlusD";
	props[kCAProxyLayerSaturation]=@"2.7";
	proxy.proxyProperties=props;
	proxy.compositingFilter=[CAFilter filterWithType:kCAFilterCopy];
}

__attribute__((constructor))
void load()
{
	traceLog=true;
	swizzleImp(@"NSVisualEffectView",@"updateLayer",true,(IMP)fake_ul,&real_ul);
}