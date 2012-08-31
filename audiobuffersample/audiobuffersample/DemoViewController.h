//
//  DemoViewController.h
//  audiobuffersample
//
//  Created by Jordan Zucker on 8/30/12.
//  Copyright (c) 2012 Jordan Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioBufferPlayer.h"
#import "Synth.h"

@interface DemoViewController : UIViewController <AudioBufferPlayerDelegate>
{
	AudioBufferPlayer* player;
	Synth* synth;
	NSLock* synthLock;
}

- (IBAction)keyDown:(id)sender;
- (IBAction)keyUp:(id)sender;

@end