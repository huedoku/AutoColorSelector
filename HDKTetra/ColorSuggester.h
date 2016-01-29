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
#define NOTIOS_BUILD

#ifdef IOS_BUILD
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#define ALGO_HISTOGRAM          101
#define ALGO_OPPOSITE12         102
#define ALGO_HUEHISTOGRAM       103
#define ALGO_SHRUNK             104
#define MAX_CLUMPS 256
#define MAX_CLUMP_DATA 256

#define TOPTENCOUNT 256
@interface ColorSuggester : NSObject
{
    int width1,height1,width2,height2;
    int numPixels1,numPixels2;
    int *cArray1;

    //ios-specific stuff
#ifdef IOS_BUILD
    UIImage *workImage1;
    UIImage *workImage2;
    UIColor *brightestPixel;
    UIColor *darkestPixel;
    UIColor *mostSaturatedPixel;
    UIColor *leastSaturatedPixel;
    UIColor *mostRedPixel;
    UIColor *mostGreenPixel;
    UIColor *mostBluePixel;
    UIColor *mostCyanPixel;
    UIColor *mostMagentaPixel;
    UIColor *mostYellowPixel;
#else
    NSImage *workImage1;
    NSImage *workImage2;
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
#endif
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

    int smartIndices[16];
    int smartCount;
    

}

@property (nonatomic , assign) int       whichAlgo;
@property (nonatomic , assign) int       binThresh;
@property (nonatomic , assign) float     rgbDiffThresh;
@property (nonatomic , assign) int       binCount;
@property (nonatomic , assign) int       binAfterThreshCount;
@property (nonatomic , assign) int       rowSkip;


-(void) loadReduced : (unsigned char *) rgbarray : (int) w : (int) h;
-(void) analyze;
-(void)       dump;
-(CGPoint) getNthPopularXY : (int) n;
-(CGPoint) getNthReducedXY : (int) n;
-(int) getNthReducedPopulation : (int) n;
-(int) getWidth1;
-(int) getHeight1;
-(int) getReducedCount;
-(NSString *) getAlgoDesc;
-(int) getNthSmartIndex : (int) n;
- (void) RGBtoHLS : (int) RR : (int) GG : (int) BB;


#ifdef IOS_BUILD
-(UIColor *) getNthPopularColor: (int) n;
-(UIColor *) getNthReducedColor: (int) n;
-(void) algo_histogram :(UIImage *)input;
-(void) algo_opposites :(UIImage *)input;
-(void) algo_shrunk :(UIImage *)input;
#else
-(NSColor *) getNthPopularColor: (int) n;
-(NSColor *) getNthReducedColor: (int) n;
-(void) algo_histogram :(NSImage *)input;
-(void) algo_opposites :(NSImage *)input;
-(NSImage *)preprocessImage : (NSImage *)inputImage : (int) blockSize : (int) colorDepth;
-(void) algo_shrunk :(NSImage *)input;
#endif

-(int) getHHH;
-(int) getLLL;
-(int) getSSS;



@end