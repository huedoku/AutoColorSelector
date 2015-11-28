//
//    ____      _            ____                              _
//   / ___|___ | | ___  _ __/ ___| _   _  __ _  __ _  ___  ___| |_ ___ _ __
//  | |   / _ \| |/ _ \| '__\___ \| | | |/ _` |/ _` |/ _ \/ __| __/ _ \ '__|
//  | |__| (_) | | (_) | |   ___) | |_| | (_| | (_| |  __/\__ \ ||  __/ |
//   \____\___/|_|\___/|_|  |____/ \__,_|\__, |\__, |\___||___/\__\___|_|
//                                       |___/ |___/
//
//
//  ColorSuggester.h
//  Huedoku Pix
//
//  Created by Dave Scruton on 11/4/15.
//  Copyright © 2015 huedoku, inc. All rights reserved.
//
//#import <UIKit/UIKit.h>
#import <Cocoa/Cocoa.h>

#define TOPTENCOUNT 30
@interface CColorSuggester : NSObject
{
    NSImage *workImage1;
    NSImage *workImage2;
    int width1,height1,width2,height2;
    int numPixels1,numPixels2;
    
    int *cArray1;
    NSColor *brightestPixel;
    NSColor *darkestPixel;
    NSColor *mostSaturatedPixel;
    NSColor *leastSaturatedPixel;
    NSColor *mostRedPixel;
    NSColor *mostGreenPixel;
    NSColor *mostBluePixel;
    NSColor *mostCyanPixel;
    NSColor *mostMagentaPixel;
    NSColor *mostYellowPixel;
    int brightestIndex;
    int darkestIndex;
    int mostSaturatedIndex;
    int leastSaturatedIndex;
    int mostRedIndex;
    int mostGreenIndex;
    int mostBlueIndex;
    int mostCyanIndex;
    int mostMagentaIndex;
    int mostYellowIndex;
    
    
    NSMutableArray *topTenColors;
    CGPoint topTenXY[TOPTENCOUNT];

    NSMutableArray *reducedColors;
    CGPoint reducedXY[TOPTENCOUNT];

    int topTenLocations[32];
}
//@property (nonatomic , strong) NSString* fromUser;
//@property (nonatomic , assign) int       uniquePuzzleId;

-(void) load : (NSImage *) input;
-(void) analyze;
-(void)       dump;
-(CGPoint) getNthPopularXY : (int) n;
-(NSColor *) getNthPopularColor: (int) n;
-(CGPoint) getNthReducedXY : (int) n;
-(NSColor *) getNthReducedColor: (int) n;
//-(ColorSuggester *)    copy;
-(int) getWidth1;
-(int) getHeight1;


@end