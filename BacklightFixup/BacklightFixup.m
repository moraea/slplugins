// clang -fmodules BacklightFixup.m -dynamiclib -o BacklightFixup.dylib && cp ./BackLightFixup.dylib /Library/Application\ Support/SkyLightPlugins && codesign -f -s - BacklightFixup.dylib

@import Foundation;

@interface Load:NSObject
@end

@implementation Load

+(void)load
{
	// run ps to get list of running processes
	NSTask *listProcesses = [NSTask new];
	listProcesses.launchPath = @"/bin/ps";
	listProcesses.arguments = @[@"-ax"];
	
	// capture stdout
	NSPipe *pipe = [NSPipe pipe];
	listProcesses.standardOutput = pipe;

	NSFileHandle *file = [pipe fileHandleForReading];
	[listProcesses launch];
	
	//write stdout to NSString
	NSData *data = [file readDataToEndOfFile];
	NSString *psOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	if(![psOutput containsString:@"TouchBarServer"]){
		NSLog(@"Moraea: Starting TouchBarServer...");
		
		NSTask *startTBS = [[NSTask alloc] init];
		startTBS.launchPath = @"/usr/libexec/TouchBarServer";
		
		[startTBS launch];		
	}
}

@end