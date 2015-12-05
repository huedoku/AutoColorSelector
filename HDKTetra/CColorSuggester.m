//
//    ____      _            ____                              _
//   / ___|___ | | ___  _ __/ ___| _   _  __ _  __ _  ___  ___| |_ ___ _ __
//  | |   / _ \| |/ _ \| '__\___ \| | | |/ _` |/ _` |/ _ \/ __| __/ _ \ '__|
//  | |__| (_) | | (_) | |   ___) | |_| | (_| | (_| |  __/\__ \ ||  __/ |
//   \____\___/|_|\___/|_|  |____/ \__,_|\__, |\__, |\___||___/\__\___|_|
//                                       |___/ |___/
//
//  ColorSuggester.m
//  Huedoku Pix
//
//  Created by Dave Scruton on 11/4/15.
//  Copyright © 2015 huedoku, inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CColorSuggester.h"

@implementation CColorSuggester

int HHH,LLL,SSS;
#define  HLSMAX   255   // H,L, and S vary over 0-HLSMAX
#define  RGBMAX   255   // R,G, and B vary over 0-RGBMAX

#define MAX_HIST_BINS 256*256*256
int hverbose = 1;

#define INV255 0.00392156
//Note: we need a little fudge factor here
//  to get our colors back from the bin's colorspace
#define INV255FUDGE 0.00392160

//=====[ColorSuggester]======================================================================
// Just clears our our object...
-(instancetype) init
{
    if (self = [super init])
    {
        
        workImage1      = nil;
        workImage2      = nil;
        topTenColors    = [[NSMutableArray alloc] init];
        reducedColors   = [[NSMutableArray alloc] init];

        numPixels1  = 0;
        numPixels2  = 0;
        width1 = height1 = width2 = height2 = 0;
        
        brightestPixel      = [NSColor blackColor];
        darkestPixel        = [NSColor blackColor];
        mostSaturatedPixel  = [NSColor blackColor];
        leastSaturatedPixel = [NSColor blackColor];
        mostRedPixel        = [NSColor blackColor];
        mostGreenPixel      = [NSColor blackColor];
        mostBluePixel       = [NSColor blackColor];
        mostCyanPixel       = [NSColor blackColor];
        mostMagentaPixel    = [NSColor blackColor];
        mostYellowPixel     = [NSColor blackColor];
        brightestIndex      = 0;
        darkestIndex        = 0;
        mostSaturatedIndex  = 0;
        leastSaturatedIndex = 0;
        mostRedIndex        = 0;
        mostGreenIndex      = 0;
        mostBlueIndex       = 0;
        mostCyanIndex       = 0;
        mostMagentaIndex    = 0;
        mostYellowIndex     = 0;
    }
    
    return self;
} //end init


//=====[ColorSuggester]======================================================================
-(void) load:(NSImage *)input
{
    workImage1 = input; //Does this copy it in???
    width1     = workImage1.size.width;
    height1    = workImage1.size.height;
    if (hverbose) NSLog(@" loading wh %d %d",width1,height1);
    cArray1 = (int *)malloc(3*width1*height1*sizeof(int));
    [self getRGBAsFromImage:workImage1];
    [self analyze];
    [self createHistogram];
    //NO NEED NOW[self findTopTenColorsXY];
    [self reduceColors];
    if (hverbose) [self dump];
    free(cArray1);

} //end load

//=====[ColorSuggester]======================================================================
-(void) getRGBAsFromImage:(NSImage*)image
{
    int width,height;
    // First get the image into your data buffer
    
    
//    CGImageRef imageRef = [UIImage CGImage];
//    NSUInteger width    = CGImageGetWidth(imageRef);
//    NSUInteger height   = CGImageGetHeight(imageRef);
//    if (hverbose) NSLog(@" ...get rgbs from image wh %d %d",(int)width,(int)height);
//
//    
//    
//    
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
//    NSUInteger bytesPerPixel = 4;
//    NSUInteger bytesPerRow = bytesPerPixel * width;
//    NSUInteger bitsPerComponent = 8;
//    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
//                                                 bitsPerComponent, bytesPerRow, colorSpace,
//                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
//    CGColorSpaceRelease(colorSpace);
//    
//    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
//    CGContextRelease(context);
    
//    NSString* imageName=[[NSBundle mainBundle] pathForResource:@"/Users/me/Temp/oxberry.jpg" ofType:@"JPG"];
//    NSImage*  tempImage=[[NSImage alloc] initWithContentsOfFile:imageName];
    NSBitmapImageRep* imageRep  =[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    unsigned char* rawData      = [imageRep bitmapData];
    int bitsPerPixel            = (int)[imageRep bitsPerPixel];
    int bytesPerPixel = bitsPerPixel/8;
    width                       = image.size.width;
    height                      = image.size.height;
    NSLog(@" bitsperpixel %d bytes %d",bytesPerPixel, 4*width*height);
    
    int cArrayPtr = 0;
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = 0;
    numPixels1 = (int)width * (int)height; //Loop over all image data...
    int row = 0;
    for (int i = 0 ; i < numPixels1 ; i++)
    {
        //CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
        CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / 255.0f;
        CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / 255.0f;
        CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / 255.0f;
        int ired   =  (int)rawData[byteIndex];
        int igreen =  (int)rawData[byteIndex + 1];
        int iblue  =  (int)rawData[byteIndex + 2];
        byteIndex += bytesPerPixel;
        cArray1[cArrayPtr++] = ired;
        cArray1[cArrayPtr++] = igreen;
        cArray1[cArrayPtr++] = iblue;
        if ((hverbose == 2) && (i % width == 0))
        {
            row = i/width;
            NSLog(@" row %d rgb %f %f %f ",row,(float)red,(float)green,(float)blue);
        }
    }
    
//    free(rawData);
} //end getRGBAsFromImage


//=====[ColorSuggester]======================================================================
-(void) analyze
{
    CGFloat tbright = 0.0;
    CGFloat tdark   = 10.0;
    int tmaxSat     = 0;
    int tminSat     = 9999;
    float cdiff;
    float redDiff     = 10.0;
    float greenDiff   = 10.0;
    float blueDiff    = 10.0;
    float cyanDiff    = 10.0;
    float magentaDiff = 10.0;
    float yellowDiff  = 10.0;
    CGFloat tred,tgreen,tblue,trgb;
    int red255,green255,blue255;
    NSColor *tmpc;
    
    //Loop over image; accumulate stats..
    int cArrayPtr = 0;
    for (int i = 0 ; i < numPixels1 ; i++)
    {
        //Get next color
        tred   = cArray1[cArrayPtr++];
        tgreen = cArray1[cArrayPtr++];
        tblue  = cArray1[cArrayPtr++];
        trgb     = tred + tgreen + tblue;
        tmpc = [NSColor colorWithRed:(float)tred*INV255 green:(float)tgreen*INV255 blue:(float)tblue*INV255 alpha:1];
        [self RGBtoHLS:red255 :green255 :blue255];
        if (trgb > tbright) //Check for brightest pixel...
        {
            brightestPixel = tmpc;
            brightestIndex = i;
            tbright        = trgb;
        }
        if (trgb < tdark) //Check for darkest pixel...
        {
            darkestPixel = tmpc;
            darkestIndex = i;
            tdark        = trgb;
        }
        if (SSS > tmaxSat) //Check for most Saturated pixel...
        {
            mostSaturatedPixel = tmpc;
            mostSaturatedIndex = i;
            tmaxSat            = SSS;
        }
        if (SSS < tminSat) //Check for least Saturated pixel...
        {
            leastSaturatedPixel = tmpc;
            leastSaturatedIndex = i;
            tminSat             = SSS;
        }

        cdiff = [self colorDifference: tmpc : [NSColor redColor]];
        if (cdiff < redDiff)
        {
            mostRedIndex = i;
            mostRedPixel = tmpc;
            redDiff      = cdiff;
        }
        cdiff = [self colorDifference: tmpc : [NSColor greenColor]];
        if (cdiff < greenDiff)
        {
            mostGreenIndex = i;
            mostGreenPixel = tmpc;
            greenDiff      = cdiff;
        }
        cdiff = [self colorDifference: tmpc : [NSColor blueColor]];
        if (cdiff < blueDiff)
        {
            mostBlueIndex = i;
            mostBluePixel = tmpc;
            blueDiff      = cdiff;
        }
        cdiff = [self colorDifference: tmpc : [NSColor cyanColor]];
        if (cdiff < cyanDiff)
        {
            mostCyanIndex = i;
            mostCyanPixel = tmpc;
            cyanDiff      = cdiff;
        }
        cdiff = [self colorDifference: tmpc : [NSColor magentaColor]];
        if (cdiff < magentaDiff)
        {
            mostMagentaIndex = i;
            mostMagentaPixel = tmpc;
            magentaDiff      = cdiff;
        }
        cdiff = [self colorDifference: tmpc : [NSColor yellowColor]];
        if (cdiff < yellowDiff)
        {
            mostYellowIndex = i;
            mostYellowPixel = tmpc;
            yellowDiff      = cdiff;
        }
   } //end i loop
    if (hverbose)
    {
        NSLog(@" Bitmap Color Analysis: (size %d x %d)",width1,height1);
        NSLog(@"   brightest RGB   at %d,%d : %@",brightestIndex%width1,brightestIndex/width1,brightestPixel);
        NSLog(@"   darkest   RGB   at %d,%d : %@",darkestIndex%width1,darkestIndex/width1,darkestPixel);
        NSLog(@"   most  saturated at %d,%d : %@",mostSaturatedIndex%width1,mostSaturatedIndex/width1,mostSaturatedPixel);
        NSLog(@"   least saturated at %d,%d : %@",leastSaturatedIndex%width1,leastSaturatedIndex/width1,leastSaturatedPixel);
        NSLog(@"   most  red       at %d,%d : %@",mostRedIndex%width1,mostRedIndex/width1,mostRedPixel);
        NSLog(@"   most  green     at %d,%d : %@",mostGreenIndex%width1,mostGreenIndex/width1,mostGreenPixel);
        NSLog(@"   most  blue      at %d,%d : %@",mostBlueIndex%width1,mostBlueIndex/width1,mostBluePixel);
        NSLog(@"   most  cyan      at %d,%d : %@",mostCyanIndex%width1,mostCyanIndex/width1,mostCyanPixel);
        NSLog(@"   most  magenta   at %d,%d : %@",mostMagentaIndex%width1,mostMagentaIndex/width1,mostMagentaPixel);
        NSLog(@"   most  yellow    at %d,%d : %@",mostYellowIndex%width1,mostYellowIndex/width1,mostYellowPixel);
    }
    
}    //end analyze

//=====[ColorSuggester]======================================================================
// MOVE THIS TO UTILS??? but how to return HH/LL/SS??
- (void) RGBtoHLS : (int) RR : (int) GG : (int) BB
{
    int cMax,cMin;      /* max and min RGB values */
    int  Rdelta,Gdelta,Bdelta; /* intermediate value: % of spread from max */
    
    
    /* calculate lightness */
    cMax = fmax( fmax(RR,GG), BB);
    cMin = fmin( fmin(RR,GG), BB);
    LLL = ( ((cMax+cMin)*HLSMAX) + RGBMAX )/(2*RGBMAX);
    
    if (cMax == cMin) {            /* r=g=b --> achromatic case */
        SSS = 0;                   /* saturation */
        HHH = 0;					 /* hue */
        //NSLog(@"bad hue... RGB %d %d %d",R,G,B);
    }
    else {                        /* chromatic case */
        /* saturation */
        if (LLL <= (HLSMAX/2))
            SSS = ( ((cMax-cMin)*HLSMAX) + ((cMax+cMin)/2) ) / (cMax+cMin);
        else
            SSS = ( ((cMax-cMin)*HLSMAX) + ((2*RGBMAX-cMax-cMin)/2) )
            / (2*RGBMAX-cMax-cMin);
        
        /* hue */
        Rdelta = ( ((cMax-RR)*(HLSMAX/6)) + ((cMax-cMin)/2) ) / (cMax-cMin);
        Gdelta = ( ((cMax-GG)*(HLSMAX/6)) + ((cMax-cMin)/2) ) / (cMax-cMin);
        Bdelta = ( ((cMax-BB)*(HLSMAX/6)) + ((cMax-cMin)/2) ) / (cMax-cMin);
        
        if (RR == cMax)
        {
            HHH = Bdelta - Gdelta;
            //NSLog(@"H1... bgdel %d %d",Bdelta,Gdelta);
        }
        else if (GG == cMax)
        {
            HHH = (HLSMAX/3) + Rdelta - Bdelta;
            //NSLog(@"H2... bgdel %d %d",Rdelta,Bdelta);
        }
        else /* BB == cMax */
        {
            HHH = ((2*HLSMAX)/3) + Gdelta - Rdelta;
            //NSLog(@"H3... grdel %d %d",Gdelta,Rdelta);
        }
        
        while (HHH < 0)
            HHH += HLSMAX;
        while (HHH > HLSMAX)
            HHH -= HLSMAX;
        //NSLog(@" hls %d %d %d",HHH,LLL,SSS);
    }
} //end RGBtoHLS



//=====[ColorSuggester]======================================================================
-(float) colorDifference : (NSColor *)c1 : (NSColor *)c2
{
    float diff = 0;
    const CGFloat* components1;
    const CGFloat* components2;
    components1 = CGColorGetComponents(c1.CGColor);
    components2 = CGColorGetComponents(c2.CGColor);
    diff =  fabs(components1[0] - components2[0]) +
            fabs(components1[1] - components2[1]) +
            fabs(components1[2] - components2[2]);
    return diff;
} //end colorDifference

//=====[ColorSuggester]======================================================================
-(void) createHistogram
{
    int i,ssize;
    int *bins;
    bins = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *binsIndices;
    binsIndices = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *populations;
    populations = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *rcolorz;
    rcolorz = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *gcolorz;
    gcolorz = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *bcolorz;
    bcolorz = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *colorzIndices;
    colorzIndices = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    NSColor *tmpc;
    NSUInteger index;
    int hthresh,popint;
    int red,green,blue;
    const CGFloat* components;
    
   
    //Loop over image; accumulate stats..
    if (hverbose) NSLog(@" running histogram...");
    for (i=0;i<MAX_HIST_BINS;i++) bins[i] = 0;
    int cArrayPtr = 0;
    for (i = 0 ; i < numPixels1 ; i++)
    {
      //Get next color
        red   = cArray1[cArrayPtr++];
        green = cArray1[cArrayPtr++];
        blue  = cArray1[cArrayPtr++];
      //Get our index...
      index   =  (red<<16) + (green<<8) + blue;
      bins[index]++;
      binsIndices[index] = i; //Store last color location
    }
    //Get bin range, some images produce more colors than others...
    int maxBinCount = 0;
    int aveBinCount = 0;
    int aveCount = 0;
    int nextbin;
    for (i=0;i<MAX_HIST_BINS;i++)
    {
        nextbin = bins[i];
        if (nextbin > maxBinCount) maxBinCount = nextbin;
        if (nextbin > 10)
        {
            aveBinCount+=nextbin;
            if ((hverbose == 2)  && (aveCount % 32 == 0)) NSLog(@" add in bin[%d] %d",aveCount,nextbin);
            aveCount++;
        }
    }
    aveBinCount/=aveCount;
    if (hverbose) NSLog(@" max bin count: %d",maxBinCount);
    if (hverbose) NSLog(@" ave bin count: %d",aveBinCount);

    int hcount = 0;
    // Loop over ALL our bins we found, add results to output arrays...
    ssize = 0;
    hthresh = 40;
    int colorIndex,colorx,colory;
    if (hverbose) NSLog(@"  ...threshold %d",hthresh);
    for (i=0;i<MAX_HIST_BINS;i++)
    {
        popint = bins[i];
        if (popint > hthresh)
        {
            red   = (i>>16) & 0xff;
            green = (i>>8)  & 0xff;
            blue  = i       & 0xff;
            populations[ssize] = bins[i];
            rcolorz[ssize]     = red;
            gcolorz[ssize]     = green;
            bcolorz[ssize]     = blue;
            colorIndex = binsIndices[i]; //point to last index for this color
            //colorx = colorIndex%width1;
            //colory = colorIndex/width1;
            colorzIndices[ssize] = colorIndex;
            ssize++;
            hcount++;
            if (hverbose == 2) NSLog(@"  bin[%d] pop %d color (%d,%d,%d) index:%d",i,bins[i],red,green,blue,colorIndex);
        }
        //if (ssize > 100) break; //We don't need that many bins...
    }
    //Quick/dirty sort: find top ten populations
    for (i=0;i<TOPTENCOUNT;i++) topTenLocations[i] = -1;
    NSLog(@" thresh produced %d bins",ssize);
    [topTenColors removeAllObjects]; //Clear top ten colors array
    for (i=0;i<TOPTENCOUNT;i++)
    {
        int maxpop   = -1;
        int wherezit = -1;
        int found = 0;

        for (int j=0;j<ssize;j++)
        {

            int nextpop = populations[j];
            if (hverbose == 2) NSLog(@" population index %d nextpop %d maxpop %d",j,nextpop,maxpop);
            if (nextpop > maxpop)
            {
                if (hverbose == 2) NSLog(@" ...new max %d vs %d at %d",nextpop,maxpop,j);
                found = 0;
                for (int k=0;k<TOPTENCOUNT && !found;k++)
                {
                    if (j == topTenLocations[k])  found = 1; //Make sure index isn't already stored
                }    //end k loop
                if (found == 0)
                {
                    wherezit  = j;
                    maxpop    = nextpop;
                }
                
            }       //end nextpop
        }          //end j loop
        if (hverbose == 2) NSLog(@" ...store bin %d in topten %d maxpop %d",wherezit,i,maxpop);
        topTenLocations[i] = wherezit; //Store LOCATION of color in histogram population
    }             //end i loop
    //Get colors out using topten indices into histogram...
    //CGPoint ttXY;
    for (i=0;i<TOPTENCOUNT;i++)
    {
        int jj     = topTenLocations[i];
        //if (hverbose) NSLog(@" topten index %d",i);
        tmpc = [NSColor colorWithRed:(CGFloat)rcolorz[jj]*INV255 green:(CGFloat)gcolorz[jj]*INV255 blue:(CGFloat)bcolorz[jj]*INV255 alpha:1];
        [topTenColors addObject:tmpc]; //Store top ten color away...
        colorIndex = colorzIndices[i];
        colorx = colorIndex%width1;
        colory = colorIndex/width1;
        topTenXY[i] = CGPointMake(colorx,colory);
        //pull rgb components out
        if (hverbose)
        {
            components = CGColorGetComponents(tmpc.CGColor);
            red        = (int)(255*components[0]);
            green      = (int)(255*components[1]);
            blue       = (int)(255*components[2]);
            NSLog(@"  ...topten[%d] : popbin:%3.3d pop:%5.5d RGB(%3.3d,%3.3d,%3.3d) XY (%f,%f)",
                  i,jj,populations[jj],red,green,blue,topTenXY[i].x,topTenXY[i].y);
        }
    } //end for i
    free(colorzIndices);
    free(rcolorz);
    free(gcolorz);
    free(bcolorz);
    free(populations);
    free(binsIndices);
    free(bins);
    return;
} //end createHistogram

//=====[ColorSuggester]======================================================================
// We did a coarse data reduction, we only know the populations of
//   the top ten colors in the image, NOT where they actually were.
//   Now it's time to find them...
-(void) findTopTenColorsXY
{
    int margin = 0; // Try to find colors that aren't right at the edge
    int i,j,row,col;
    int found;
    NSColor *tmpc;
    NSColor *sourceColor;
    const CGFloat* componentstt;
    const CGFloat* componentssc;

    for (i=0;i<TOPTENCOUNT;i++) //let's find some colors...
    {
        tmpc = [topTenColors objectAtIndex:i];
        componentstt = CGColorGetComponents(tmpc.CGColor);
        if (hverbose) NSLog(@" find color[%d] %@",i,tmpc);
        found = 0;
        int cArrayPtr=0;
        int red,green,blue;
        for (j = 0 ; j < numPixels1 && !found ; j++)
        {
            red   = cArray1[cArrayPtr++];
            green = cArray1[cArrayPtr++];
            blue  = cArray1[cArrayPtr++];

            sourceColor = [NSColor colorWithRed:(float)red*INV255 green:(float)green*INV255 blue:(float)blue*INV255 alpha:1];
            //Compare bitmap color with our "popular" colors, get something CLOSE
            float cdiff = [self colorDifference : tmpc : sourceColor];
            componentssc = CGColorGetComponents(sourceColor.CGColor);
            if (cdiff < 0.0001)
            {
                //Check margin...
                col = j%width1; //X coord
                row = j/width1; //Y coord
                if (row > margin && col > margin && row < height1-margin && col < width1-margin)
                {
                    if (hverbose) NSLog(@" ....color %d match xy %d %d",i,row,col);
                    found = 1;
                    CGPoint ttXY =  CGPointMake(col,row);
                    topTenXY[i] = ttXY;
                }
            }
        } //end for j
    }    //end for i
    
   if (hverbose) for(i=0;i<10;i++) NSLog(@"  cgpxy %f %f",topTenXY[i].x,topTenXY[i].y);
    
} //end findTopTenColorsXY

//=====[ColorSuggester]======================================================================
-(CGPoint) getNthPopularXY : (int) n
{
    if (n < 0 || n >= TOPTENCOUNT) return CGPointMake(0, 0);
    return topTenXY[n];
} //end getNthPopularXY


//=====[ColorSuggester]======================================================================
-(NSColor *) getNthPopularColor: (int) n
{
    if (n < 0 || n >= TOPTENCOUNT) return [NSColor blackColor];
    return [topTenColors objectAtIndex:n];
} //end getNthPopularCooor

//=====[ColorSuggester]======================================================================
// Takes our 'top ten' colors and reduces them; pulls colors that are
//   similar to each other out of contention... stashes results into
//   reducedColors array; we are looking for FOUR RESULTS...
-(void) reduceColors
{
    float thresh = 0.15; //RGB difference thresh
    float cdiff;
    NSColor *tmpc1;
    NSColor *tmpc2;
    int reduceLoop;
    int i,j;
    int rcount = 0;
    [reducedColors removeAllObjects];

    int found;
    for(reduceLoop=0;reduceLoop<4;reduceLoop++)
    {
        for (i=0;i<TOPTENCOUNT;i++) //Look at all our colors...
        {
            //Get a topten color...
            tmpc1 = [topTenColors objectAtIndex:i];
            // Look for close color in reduced array, we want DIFFERENT COLORS
            found = 0;
            for (j = 0;j<[reducedColors count];j++)
            {
                tmpc2 = [reducedColors objectAtIndex:j];
                cdiff = [self colorDifference:tmpc1 :tmpc2];
                if (cdiff < thresh) found = 1;
            } //end for j
            if (!found) //No match, add to reduced array...
            {
                [reducedColors addObject:tmpc1]; //Add our color...
                reducedXY[rcount].x = topTenXY[i].x;
                reducedXY[rcount].y = topTenXY[i].y;
                rcount++;
            }
        }     //end for i
    } //end for reduceLoop
    
    
    int rfcount = (int)[reducedColors count];
    int red,green,blue;
    for (i=0;i<rfcount;i++)
    {
        const CGFloat* components;
        tmpc1      = [reducedColors objectAtIndex:i];
        components = CGColorGetComponents(tmpc1.CGColor);
        red        = (int)(255*components[0]);
        green      = (int)(255*components[1]);
        blue       = (int)(255*components[2]);
        if (hverbose) NSLog(@" reduced[%d] (%d,%d,%d) : %f,%f",i,red,green,blue,reducedXY[i].x,reducedXY[i].y);
    }
}  //end reduceColors


//=====[ColorSuggester]======================================================================
-(CGPoint) getNthReducedXY : (int) n
{
    if (n < 0 || n >= [reducedColors count]) return CGPointMake(0, 0);
    if (hverbose) NSLog(@" get reducedXY %f,%f",reducedXY[n].x,reducedXY[n].y);
    return reducedXY[n];
} //end getNthPopularXY


//=====[ColorSuggester]======================================================================
-(NSColor *) getNthReducedColor: (int) n
{
    if (n < 0 || n >= [reducedColors count]) return [NSColor blackColor];
    if (hverbose) NSLog(@" get reducedColor %@",[reducedColors objectAtIndex:n]);
    return [reducedColors objectAtIndex:n];
} //end getNthPopularCooor



//=====[ColorSuggester]======================================================================
-(void) dump
{
    int i,red,green,blue;
    NSColor *tmpc1;
    const CGFloat* components;
    NSLog(@" ColorSuggester Dump...");
    NSLog(@"   topten:");
    for (i=0;i<TOPTENCOUNT;i++)
    {
        tmpc1 = [topTenColors objectAtIndex:i];
        components = CGColorGetComponents(tmpc1.CGColor);
        red        = (int)(255*components[0]);
        green      = (int)(255*components[1]);
        blue       = (int)(255*components[2]);
        NSLog(@"  [%d]: XY %f,%f: RGB (%d,%d,%d)",i,topTenXY[i].x,topTenXY[i].y,red,green,blue);
    }
    NSLog(@"   reduced:");
    for (i=0;i<[reducedColors count];i++)
    {
        tmpc1 = [reducedColors objectAtIndex:i];
        components = CGColorGetComponents(tmpc1.CGColor);
        red        = (int)(255*components[0]);
        green      = (int)(255*components[1]);
        blue       = (int)(255*components[2]);
        NSLog(@"  [%d]: XY %f,%f: RGB (%d,%d,%d)",i,reducedXY[i].x,reducedXY[i].y,red,green,blue);
    }
    
} //end dump

//=====[ColorSuggester]======================================================================
-(int) getWidth1
{
    return width1;
}

//=====[ColorSuggester]======================================================================
-(int) getHeight1
{
    return height1;
}

@end
