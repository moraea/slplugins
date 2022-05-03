// osascript -e 'tell app "Finder" to quit'
// clang -fmodules -dynamiclib -I ../../non-metal-common/Utils blurtest4d.m -F /System/Library/PrivateFrameworks -framework SkyLight -o /tmp/b.dylib -Wno-unused-getter-return-value && codesign -f -s - /tmp/b.dylib && DYLD_INSERT_LIBRARIES=/tmp/b.dylib /S*/L*/C*/F*/C*/M*/Finder

#import "Utils.h"
@import AppKit;

extern id kCAProxyLayerMaterial;
extern id kCAProxyLayerBlendMode;
extern id kCAProxyLayerActive;
extern id kCAProxyLayerSaturation;
extern id kCAProxyLayerSelectionTintColor;

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

@interface CAProxyLayer:CALayer
-(void)setProxyProperties:(NSDictionary*)rdx;
@end

@interface CAFilter:NSObject
+(instancetype)filterWithType:(id)rdx;
@end

Class dynamic__NSViewBackingLayer;

BOOL SLSGetAppearanceThemeLegacy();

@interface NSVisualEffectView(Private)
-(BOOL)_shouldUseActiveAppearance;
@end

// all blacklisting/materials logic should be put here now - Amy

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

void (*real_updateLayer)(NSVisualEffectView*,SEL);
void fake_updateLayer(NSVisualEffectView* self,SEL sel)
{
	real_updateLayer(self,sel);
	
	// first, see if we already added a proxy layer
	// otherwise, put a new one below any AppKit layers that are already here
	
	CAProxyLayer* proxy=nil;
	int firstAK=self.layer.sublayers.count-1;
	for(int i=0;i<self.layer.sublayers.count;i++)
	{
		CALayer* layer=self.layer.sublayers[i];
		
		// TODO: instead of searching every time, can use associated object?
		
		if([layer isKindOfClass:CAProxyLayer.class])
		{
			proxy=(CAProxyLayer*)layer;
			break;
		}
		
		if([layer isKindOfClass:dynamic__NSViewBackingLayer])
		{
			firstAK=i;
			break;
		}
	}
	
	if(!proxy)
	{
		proxy=CAProxyLayer.layer;
		proxy.compositingFilter=[CAFilter filterWithType:kCAFilterCopy];
		[self.layer insertSublayer:proxy atIndex:firstAK];
	}
	
	NSString* material=materialForView(self);
	
	if(material)
	{
		proxy.hidden=false;
		
		NSMutableDictionary* props=NSMutableDictionary.alloc.init.autorelease;
		props[kCAProxyLayerMaterial]=material;
		props[kCAProxyLayerActive]=@true;
		props[kCAProxyLayerBlendMode]=@"P";
		props[kCAProxyLayerSaturation]=@2.7;
		proxy.proxyProperties=props;
		
		CGRect bounds=self.frame;
		bounds.origin=CGPointZero;
		proxy.frame=bounds;
	}
	else
	{
		proxy.hidden=true;
	}
}

__attribute__((constructor))
void load()
{
	// traceLog=true;
	swizzleImp(@"NSVisualEffectView",@"updateLayer",true,(IMP)fake_updateLayer,(IMP*)&real_updateLayer);
	
	dynamic__NSViewBackingLayer=NSClassFromString(@"_NSViewBackingLayer");
	
	[NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillMiniaturizeNotification object:nil queue:nil usingBlock:^(NSNotification* note)
	{
		NSApp.keyWindow.resignKeyWindow;
		NSApp.mainWindow.resignMainWindow;
	}];
}