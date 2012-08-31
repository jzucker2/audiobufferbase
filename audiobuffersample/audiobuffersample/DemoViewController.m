//
//  DemoViewController.m
//  audiobuffersample
//
//  Created by Jordan Zucker on 8/30/12.
//  Copyright (c) 2012 Jordan Zucker. All rights reserved.
//

#import "DemoViewController.h"

@implementation DemoViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // We need a lock because we will update the Synth's state from the
		// main thread (whenever the user presses a button), but we will read
		// its state from an audio thread in the AudioBufferPlayerDelegate
		// callback. We want to prevent doing both at the same time.
		synthLock = [[NSLock alloc] init];
        
		// The Synth and the AudioBufferPlayer must use the same sample rate.
		// Note that the iPhone is a lot slower than a desktop computer, so
		// choose a sample rate that is not too high and a buffer size that is
		// not too low. For example, a buffer size of 800 packets and a sample
		// rate of 16000 Hz means you need to fill up the buffer in less than
		// 0.05 seconds. If it takes longer, the sound will crack up.
		float sampleRate = 16000.0f;
        
		// Create the synthesizer before we create the AudioBufferPlayer, because
		// the AudioBufferPlayer will ask for buffers right away when we start it.
		synth = [[Synth alloc] initWithSampleRate:sampleRate];
        
		// Create the AudioBufferPlayer, set ourselves as the delegate, and start it.
		player = [[AudioBufferPlayer alloc] initWithSampleRate:sampleRate channels:1 bitsPerChannel:16 packetsPerBuffer:1024];
		player.delegate = self;
		player.gain = 0.9f;
		[player start];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    NSLog(@"initWithCoder");
	if ((self = [super initWithCoder:decoder]))
	{
		// We need a lock because we will update the Synth's state from the
		// main thread (whenever the user presses a button), but we will read
		// its state from an audio thread in the AudioBufferPlayerDelegate
		// callback. We want to prevent doing both at the same time.
		synthLock = [[NSLock alloc] init];
        
		// The Synth and the AudioBufferPlayer must use the same sample rate.
		// Note that the iPhone is a lot slower than a desktop computer, so
		// choose a sample rate that is not too high and a buffer size that is
		// not too low. For example, a buffer size of 800 packets and a sample
		// rate of 16000 Hz means you need to fill up the buffer in less than
		// 0.05 seconds. If it takes longer, the sound will crack up.
		float sampleRate = 16000.0f;
        
		// Create the synthesizer before we create the AudioBufferPlayer, because
		// the AudioBufferPlayer will ask for buffers right away when we start it.
		synth = [[Synth alloc] initWithSampleRate:sampleRate];
        
		// Create the AudioBufferPlayer, set ourselves as the delegate, and start it.
		player = [[AudioBufferPlayer alloc] initWithSampleRate:sampleRate channels:1 bitsPerChannel:16 packetsPerBuffer:1024];
		player.delegate = self;
		player.gain = 0.9f;
		[player start];
	}
	return self;
}

- (void)dealloc
{
	[player release];
	[synth release];
	[synthLock release];
    
	[super dealloc];
}

- (IBAction)keyDown:(id)sender
{
	[synthLock lock];
    
    NSLog(@"keyDown");
	// The tag of each button corresponds to its MIDI note number.
	int midiNote = ((UIButton*)sender).tag;
	[synth playNote:midiNote];
	
	[synthLock unlock];
}

- (IBAction)keyUp:(id)sender
{
	[synthLock lock];
    
    NSLog(@"keyUp");
    
	int midiNote = ((UIButton*)sender).tag;
	[synth releaseNote:midiNote];
    
	[synthLock unlock];
}

#pragma mark -
#pragma mark AudioBufferPlayerDelegate

- (void)audioBufferPlayer:(AudioBufferPlayer*)audioBufferPlayer fillBuffer:(AudioQueueBufferRef)buffer format:(AudioStreamBasicDescription)audioFormat
{
	// Lock access to the synth. This delegate callback runs on an internal
	// Audio Queue thread, and we don't want to allow the main UI thread to
	// change the Synth's state while we're filling up the audio buffer.
	[synthLock lock];
    
	// Calculate how many packets fit into this buffer. Remember that a packet
	// equals one frame because we are dealing with uncompressed audio, and a
	// frame is a set of left+right samples for stereo sound, or a single sample
	// for mono sound. Each sample consists of one or more bytes. So for 16-bit
	// mono sound, each packet is 2 bytes. For stereo it would be 4 bytes.
	int packetsPerBuffer = buffer->mAudioDataBytesCapacity / audioFormat.mBytesPerPacket;
    
	// Let the Synth write into the buffer. Note that we could have made Synth
	// be the AudioBufferPlayerDelegate, but I like to separate the synthesis
	// part from the audio engine. The Synth just knows how to fill up buffers
	// in a particular format and does not care where they come from.
	int packetsWritten = [synth fillBuffer:buffer->mAudioData frames:packetsPerBuffer];
    
	// We have to tell the buffer how many bytes we wrote into it.
	buffer->mAudioDataByteSize = packetsWritten * audioFormat.mBytesPerPacket;
    
	[synthLock unlock];
}

#pragma mark - Calculate midi note

- (int) calculateMidiNote:(CGPoint)point
{
    //int midiNote = point.x%108;
    int midiNote = fmodf(point.x, 108);
    if (midiNote<21) {
        midiNote = 21;
    }
    return midiNote;
}

#pragma mark - Receive Touches

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    
    NSLog(@"+++++");
    NSLog(@"touchesBegan");
    NSLog(@"touchPoint is (%f, %f)", touchPoint.x, touchPoint.y);
    NSLog(@"+++++");
    
    [synthLock lock];
    // The tag of each button corresponds to its MIDI note number.
	//int midiNote = ((UIButton*)sender).tag;
    int midiNote = [self calculateMidiNote:touchPoint];
	[synth playNote:midiNote];
	
	[synthLock unlock];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    CGPoint touchPoint = [touch locationInView:self.view];
//    
//    NSLog(@"*****");
//    NSLog(@"touchesMoved");
//    NSLog(@"touchPoint is (%f, %f)", touchPoint.x, touchPoint.y);
//    NSLog(@"*****");
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    CGPoint touchPoint = [touch locationInView:self.view];
//    
//    NSLog(@"=====");
//    NSLog(@"touchesEnded");
//    NSLog(@"touchPoint is (%f, %f)", touchPoint.x, touchPoint.y);
//    NSLog(@"=====");
//    
//    [synthLock lock];
//        
//	//int midiNote = ((UIButton*)sender).tag;
//	//[synth releaseNote:midiNote];
//    
//    [synthLock unlock];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Most likely won't call this
    //UITouch *touch = [touches anyObject];
    NSLog(@"-----touchesCancelled-----");
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}



@end
