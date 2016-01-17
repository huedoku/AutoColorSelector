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
//  NOTE:    This version is similar to but different from the iOS
//            version, be careful cross-integrating!
//
//  Created by Dave Scruton on 11/4/15.
//  Copyright © 2015 huedoku, inc. All rights reserved.
//
//#import <UIKit/UIKit.h>
#import <Cocoa/Cocoa.h>


#define ALGO_HISTOGRAM          101
#define ALGO_OPPOSITE12         102
#define ALGO_HUEHISTOGRAM       103
#define MAX_CLUMPS 256
#define MAX_CLUMP_DATA 256

#define TOPTENCOUNT 8192
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
    int topTenPopulations[TOPTENCOUNT];
    int topTenColorIndices[TOPTENCOUNT];
    NSMutableArray *reducedColors;
    CGPoint reducedXY[TOPTENCOUNT];
    int reducedPopulations[TOPTENCOUNT];
    int topTenLocations[TOPTENCOUNT];
    int topTenHues[TOPTENCOUNT];
    int topTenHRGB[TOPTENCOUNT][3];
    int numClumps;
    int clumpPtrs[MAX_CLUMPS];
    int clumpSizes[MAX_CLUMPS];
    int clumpData[MAX_CLUMPS][MAX_CLUMP_DATA]; //Points to color data
    int clumpXY[MAX_CLUMPS][MAX_CLUMP_DATA];
    
    
}

@property (nonatomic , assign) int       whichAlgo;
@property (nonatomic , assign) int       binThresh;
@property (nonatomic , assign) float     rgbDiffThresh;
@property (nonatomic , assign) int       binCount;
@property (nonatomic , assign) int       binAfterThreshCount;

//@property (nonatomic , strong) NSString* fromUser;
//@property (nonatomic , assign) int       uniquePuzzleId;

-(void) loadReduced : (unsigned char *) rgbarray : (int) w : (int) h;
-(void) analyze;
-(void)       dump;
-(CGPoint) getNthPopularXY : (int) n;
-(NSColor *) getNthPopularColor: (int) n;
-(CGPoint) getNthReducedXY : (int) n;
-(NSColor *) getNthReducedColor: (int) n;
-(int) getNthReducedPopulation : (int) n;
//-(ColorSuggester *)    copy;
-(int) getWidth1;
-(int) getHeight1;
-(int) getReducedCount;
-(NSString *) getAlgoDesc;

-(void) algo_histogram :(NSImage *)input;
-(void) algo_opposites :(NSImage *)input;
-(void) algo_huehistogram :(NSImage *)input;
-(NSImage *)preprocessImage : (NSImage *)inputImage : (int) blockSize : (int) colorDepth;




@end