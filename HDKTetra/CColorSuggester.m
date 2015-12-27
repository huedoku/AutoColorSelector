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
//  NOTE:    This version is similar to but different from the iOS
//            version, be careful cross-integrating!
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
int hverbose = 0;   //1 = minimal, 2 = medium 3 = outrageous

#define INV255 0.00392156
//Note: we need a little fudge factor here
//  to get our colors back from the bin's colorspace
#define INV255FUDGE 0.00392160

NSString *histDesc = @"Histogram: finds most popular colors.\n Uses bin threshold to eliminate less\n popular colors.  Sorts thresholded\n colors into a top-ten array. Finally,\n compares top-ten colors for similarity\n and eliminates near-identical colors.";
NSString *opposite12Desc = @"Opposite 1/2: Finds most popular\n color. Uses histogram to get a list\n of top-ten most popular colors.\n Finds most opposite color in top-ten\n list. Finds median color between\n opposites in top-ten list. Lastly\n finds opposite of median color.";

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
        
        _binThresh = 10;
        _rgbDiffThresh = 0.05;
        
        _whichAlgo = ALGO_HISTOGRAM;

    }
    
    return self;
} //end init





//=====[ColorSuggester]======================================================================
-(void) loadInput :(NSImage *)input
{
    workImage1 = input; //Does this copy it in???
    width1     = workImage1.size.width;
    height1    = workImage1.size.height;
    NSLog(@" AutoColor Loading for algo %d wh %d %d",_whichAlgo,width1,height1);
    cArray1 = (int *)malloc(3*width1*height1*sizeof(int));
    [self getRGBAsFromImage:workImage1];
    [self analyze];
    
}

//=====[ColorSuggester]======================================================================
-(void) cleanup
{
    free(cArray1);
}



//=====[ColorSuggester]======================================================================
-(void) algo_histogram :(NSImage *)input
{
    [self loadInput:input];
    [self createHistogram];
    [self createClumps];
    [self reduceColors];
    [self refindColors];
    if (hverbose) [self dump];
    [self cleanup];
}

//=====[ColorSuggester]======================================================================
-(void) algo_opposites:(NSImage *)input  
{
    [self loadInput:input];
    [self createHistogram];
    [self createClumps];
    [self findOpposites];
    [self refindColors];
    if (hverbose) [self dump];
    [self cleanup];
}

//=====[ColorSuggester]======================================================================
-(void) algo_huehistogram :(NSImage *)input
{
    [self loadInput:input];
    [self createHueHistogram];
    [self createHueClumps];
    [self reduceColors];
    [self refindColors];
    if (hverbose) [self dump];
    [self cleanup];
}




//=====[ColorSuggester]======================================================================
-(void) loadReduced : (unsigned char *) rgbarray : (int) w : (int) h
{
    width1     = w;
    height1    = h;
    numPixels1 = (int)width1 * (int)height1; //Loop over all image data...

    cArray1 = (int *)malloc(3*width1*height1*sizeof(int));

    int optr = 0;
    unsigned char r,g,b;
    int ired,igreen,iblue;
    for (int i=0;i<w*h;i++)
    {
        r = rgbarray[optr];
        g = rgbarray[optr+1];
        b = rgbarray[optr+2];
        ired   = (int)r;
        igreen = (int)g;
        iblue  = (int)b;
        cArray1[optr]   = ired;
        cArray1[optr+1] = igreen;
        cArray1[optr+2] = iblue;
        NSLog(@" carray[%d] %d %d %d",optr,cArray1[optr],cArray1[optr+1],cArray1[optr+2]);
        optr+=3;
    }
    
    [self analyze];
    //Histogram is used in more than one algo...
    [self createHistogram];
    if (hverbose) [self dump];
    free(cArray1);

} //end loadReducedImage

//=====[ColorSuggester]======================================================================
-(void) getRGBAsFromImage:(NSImage*)image
{
    int width,height;
    NSBitmapImageRep* imageRep  =[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    unsigned char* rawData      = [imageRep bitmapData];
    int bitsPerPixel            = (int)[imageRep bitsPerPixel];
    int bytesPerPixel = bitsPerPixel/8;
    width                       = image.size.width;
    height                      = image.size.height;
    //NSLog(@" bitsperpixel %d bytes %d",bytesPerPixel, 4*width*height);
    
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
        if ((hverbose == 3) && (i % width == 0)) //Sanity check, print LH pixel on each row
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
-(void) createHueHistogram
{
    int i,row,col,cArrayPtr,colorx,colory;
    int rgdiff,rbdiff,gbdiff,rgbdifftoler;
    int hueptr;
    int red,green,blue;
    int huebins[256];      //Hue bins...
    int huebinsXY[256];    //XY bins of last pixel in hue...
    int hueRGB[256][3];
    NSColor *tmpc;
    for (i=0;i<256;i++)
    {
        huebins[i] = 0;
        huebinsXY[i] = -1;
    }
    
    red = 255;green = 0;blue = 0;
    [self RGBtoHLS:red :green :blue];
    NSLog(@" test Red: 255,0,0 hue %d",HHH);
    red = 0;green = 255;blue = 0;
    [self RGBtoHLS:red :green :blue];
    NSLog(@" test Green: 0,255,0 hue %d",HHH);
    red = 0;green = 0;blue = 255;
    [self RGBtoHLS:red :green :blue];
    NSLog(@" test Blue: 255,0,0 hue %d",HHH);

    
    cArrayPtr = 0;
    rgbdifftoler = 20;
    for (i = 0 ; i < numPixels1 ; i++)
    {
        //Get next color
        red   = cArray1[cArrayPtr++];
        green = cArray1[cArrayPtr++];
        blue  = cArray1[cArrayPtr++];
        rgdiff = abs(red - green);
        gbdiff = abs(green - blue);
        rbdiff = abs(red - blue);
        if (rgdiff > rgbdifftoler || gbdiff > rgbdifftoler || rbdiff > rgbdifftoler) //Must be a NON-GREY color!
        {
            
            [self RGBtoHLS:red :green :blue];
            hueptr = HHH;
            if (hueptr < 0)   hueptr = 0;
            if (hueptr > 255) hueptr = 255;
            huebins[hueptr]++;
            if (huebins[hueptr] == 1)
            {
                huebinsXY[hueptr] = i;
                hueRGB[hueptr][0] = red;
                hueRGB[hueptr][1] = green;
                hueRGB[hueptr][2] = blue;
            }
            
        }
    }
    NSLog(@" huebins UNSORTED:");
    for (i=0;i<255;i++)
    {
        int locxy = huebinsXY[i];
        row = locxy / width1;
        col = locxy % width1;
        red   = hueRGB[i][0];
        green = hueRGB[i][1];
        blue  = hueRGB[i][2];
        if (huebins[i] > 0) NSLog(@"  hue[%d] pop %d RGB (%d,%d,%d) XY [%d,%d]",i,huebins[i],red,green,blue,col,row);
    }

    //Quick/dirty sort: find top ten populations
    for (i=0;i<256;i++)
    {
        int nextpop,icolor;
        int wherezitXY = -1;
        int wherezitRGB = 0;
        //int pixelindex = -1;
        int maxpop   = -1;
        int maxjloc  = -1;
        int maxpixelXY = -1;
        int topr = 0;
        int topg = 0;
        int topb = 0;
        icolor = 0;
        for (int j=0;j<256;j++)
        {
            nextpop    = huebins[j];
            wherezitXY = huebinsXY[j];
            red   = hueRGB[j][0];
            green = hueRGB[j][1];
            blue  = hueRGB[j][2];

            if (nextpop > maxpop)
            {
                maxpop         = nextpop;
                wherezitRGB    = red<<16 | green<<8 | blue;
                maxpixelXY     = wherezitXY;
                maxjloc        = j;
                topr           = red;
                topg           = green;
                topb           = blue;
            }
        }          //end j loop
        if (hverbose == 2) NSLog(@" tt[%d] %d %d ",i,wherezitRGB,maxpop);
        topTenLocations[i]    = wherezitRGB;
        topTenPopulations[i]  = maxpop;
        topTenColorIndices[i] = maxpixelXY;
        topTenHues[i]         = maxjloc;
        topTenHRGB[i][0]      = topr;
        topTenHRGB[i][1]      = topg;
        topTenHRGB[i][2]      = topb;
        //Zero out old max for next pass...
        huebins[maxjloc] = 0;
    }             //end i loop
    
    if (hverbose) NSLog(@"Histogram Results: (sorted)");
    for (i=0;i<TOPTENCOUNT;i++)
    {
        int RGBindex  = topTenLocations[i];
        int pop       = topTenPopulations[i];
        int pindex    = topTenColorIndices[i];
        int hue       = topTenHues[i];
        red   = (RGBindex>>16) & 0xff;
        green = (RGBindex>>8)  & 0xff;
        blue  = RGBindex       & 0xff;
        row   = pindex / width1;
        col   = pindex % width1;
        //if (hverbose) NSLog(@" topten index %d",i);
        tmpc = [NSColor colorWithRed:(CGFloat)red*INV255 green:(CGFloat)green*INV255 blue:(CGFloat)blue*INV255 alpha:1];
        [topTenColors addObject:tmpc]; //Store top ten color away...
        colorx = pindex%width1;
        colory = pindex/width1;
        topTenXY[i] = CGPointMake(colorx,colory);
        //pull rgb components out
        if (hverbose && pop > 0)
        {
            NSLog(@" [%2.2d] :  pop:%5.5d hue %d RGB(%3.3d,%3.3d,%3.3d) XY (%d,%d)",
                  i,pop,hue,red,green,blue,col,row);
        }
    } //end for i

    
    
} //end createHueHistogram

//=====[ColorSuggester]======================================================================
-(int) isHueInAClump : (int) hue
{
    int clumptoler = 10; //MUST BE LESS THAN HUETHRESH in hueclump creator!
    int i,j,hdata,whichclump = -1;
    for (i=0;i<MAX_CLUMPS;i++)
    {
        int cs = clumpSizes[i];
        if (cs > 0)
        {
            for(j=0;j<cs;j++)
            {
                hdata = clumpData[i][j];
                if (abs(hue-hdata) < clumptoler)
                {
                    return i; //FOUND!
                }
            }
        }
    }

    return whichclump;
} //end isHueInAClump


//=====[ColorSuggester]======================================================================
-(void) createHueClumps
{
    BOOL needNewClump;
    BOOL firstTime;
    int i,j,hue,lhue,huediff,cindex;
    int huethresh = 15;  //Hue diff thresh
    numClumps = 0;
    //int dataptr = 0;
    for (i=0;i<MAX_CLUMPS;i++)
    {
        clumpPtrs[i]  = -1;
        clumpSizes[i] = -1;
    }
    for (i=0;i<MAX_CLUMPS;i++)
        for (j=0;j<MAX_CLUMP_DATA;j++)
    {
        clumpData[i][j] = -1;
    }
    //OK, go through our "top ten" thresholded/sorted data and find some clumps!
    needNewClump = TRUE;
    firstTime    = TRUE;
    
   lhue = 0;
    for (i=0;i<256;i++)
    {
        hue          = topTenHues[i];
        cindex       = topTenColorIndices[i];
        if (firstTime)
        {
            lhue      = hue;
            firstTime = FALSE;
        }
        huediff = abs(hue   - lhue);
        if (huediff > huethresh) //Big color diff found? Next clump!
        {
            NSLog(@"loop %d bigthresh huediff %d  hue %d lhue %d",i,huediff,hue,lhue);
            int cfound = [self isHueInAClump:hue];
            if (cfound != -1) //Found in an existing clump?
            { //Addit to existing clump..
                int csize = clumpSizes[cfound];
                clumpData[cfound][csize] = hue;
                clumpXY[cfound][csize] = cindex;
                NSLog(@" add 2 clump[%d] %d store cindex %d",cfound,csize,cindex);
                clumpSizes[cfound]++;
            }
            else
            {
                numClumps++;
                clumpData[numClumps][0] = hue;
                clumpXY[numClumps][0] = cindex;
                needNewClump = TRUE;
            }
        }
        else
        {
            //NSLog(@" ....incr clump %d",i);
            int csize = clumpSizes[numClumps];
            clumpData[numClumps][csize] = hue;
            clumpXY[numClumps][csize] = cindex;
            NSLog(@" incr clump[%d] csize %d store cindex %d",numClumps,csize,cindex);
            clumpSizes[numClumps]++;
        }
        if (needNewClump)
        {
            NSLog(@" neednewclump %d count %d",i,numClumps);
            clumpPtrs[numClumps]  = i;
            clumpSizes[numClumps] = 0;
            lhue   = hue;
            needNewClump = FALSE;
        }
        
    } //end for i
    NSLog(@"ClumpDump:");
    NSLog(@" numclumps %d",numClumps);
    for (i=0;i<numClumps;i++)
    {
        int red,green,blue;
        int RGBindex = topTenLocations[clumpPtrs[i]];
        hue      = topTenHues[clumpPtrs[i]];

        red   = (RGBindex>>16) & 0xff;
        green = (RGBindex>>8)  & 0xff;
        blue  = RGBindex       & 0xff;
        
        //int cptr = clumpPtrs[i];
        int cindex = clumpXY[i][1];
        int row = cindex / width1;
        int col = cindex % width1;
        int csize = clumpSizes[i];
        if (hverbose > 1 && csize > 1)
            NSLog(@" clumpptr %d size %d hue %d RGB %d,%d,%d  index %d xy %d %d",clumpPtrs[i],csize,hue,red,green,blue,cindex,row,col);
        
    }
    
    
    
} //end createHueClumps



//=====[ColorSuggester]======================================================================
-(void) createHistogram
{
    int i,ssize;
    int *bins;
    bins = (int *) malloc(MAX_HIST_BINS * sizeof(int));
    int *binsthresh;
    binsthresh = (int *) malloc(MAX_HIST_BINS * sizeof(int) * 3);
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
    //const CGFloat* components;
    int row,col;
    
    NSLog(@"Running Histogram...");
    //Loop over image; accumulate stats..
    if (hverbose) NSLog(@" running histogram...");
    for (i=0;i<MAX_HIST_BINS;i++) bins[i] = 0;
    int cArrayPtr = 0;

    // Loop over all pixels.  Get RGB. Compute index to bin from RGB. Increment that bin.
    for (i = 0 ; i < numPixels1 ; i++)
    {
      //Get next color
        red   = cArray1[cArrayPtr++];
        green = cArray1[cArrayPtr++];
        blue  = cArray1[cArrayPtr++];
        //Get our index...
        index   =  (red<<16) + (green<<8) + blue;
        bins[index]++;
        if (bins[index] == 1) binsIndices[index] = i; //Store first color location (this is where last pixel was)
    }

   
    //Get # bins with anything in them at all...
    _binCount = 0;
    for (i=0;i<MAX_HIST_BINS;i++)
    {
        if (bins[i] > 0) _binCount++;
    }
    
    
    //int hcount = 0;
    _binAfterThreshCount = 0;
    // Loop over ALL our bins we found, add results to output arrays...
    ssize = 0;
    hthresh = _binThresh;
    if (hthresh < 1) hthresh = 1;
    int colorx,colory;
    int bin2ptr = 0;
    if (hverbose) NSLog(@" Culling bins below threshold %d",hthresh);
    //Produce sparse list of bins w/ populations over threshold
    for (i=0;i<MAX_HIST_BINS;i++)
    {
        popint = bins[i];
        if (popint > hthresh)
        {
            binsthresh[bin2ptr++] = i;
            binsthresh[bin2ptr++] = bins[i];
            binsthresh[bin2ptr++] = binsIndices[i];
            if (hverbose == 2) NSLog(@" binsthresh[%d] %x %d %d",bin2ptr-2,i,bins[i],binsIndices[i]);
            _binAfterThreshCount++;
        }
    }
    NSLog(@" ..sparse list has %d items",bin2ptr);

    [topTenColors removeAllObjects]; //Clear top ten colors array
    for (i=0;i<TOPTENCOUNT;i++)
    {
        topTenLocations[i]    = -1;
        topTenPopulations[i]  = -1;
        topTenColorIndices[i] = -1;
    }

    //Quick/dirty sort: find top ten populations
    for (i=0;i<TOPTENCOUNT;i++)
    {
        int maxpop   = -1;
        int wherezitRGB = -1;
        int pixelindex = -1;
        int maxjloc  = -1;
        int maxpixelindex = -1;
        int nextpop,icolor;
        icolor = 0;
        for (int j=0;j<bin2ptr;j+=3)
        {
            icolor     = binsthresh[j];
            nextpop    = binsthresh[j+1];
            pixelindex = binsthresh[j+2];
            if (nextpop > maxpop)
            {
                maxpop         = nextpop;
                wherezitRGB    = icolor;
                maxpixelindex  = pixelindex;
                maxjloc        = j;
            }
        }          //end j loop
        if (hverbose == 2) NSLog(@" tt[%d] %d %d ",i,wherezitRGB,maxpop);
        topTenLocations[i]    = wherezitRGB;
        topTenPopulations[i]  = maxpop;
        topTenColorIndices[i] = maxpixelindex;
        //Zero out old max for next pass...
        binsthresh[maxjloc+1] = 0;
    }             //end i loop

    for (i=0;i<TOPTENCOUNT;i++)
    {
        int index = topTenLocations[i];
        //int pop   = topTenPopulations[i];
        //int pindex = topTenColorIndices[i];
        red   = (index>>16) & 0xff;
        green = (index>>8)  & 0xff;
        blue  = index       & 0xff;

        //NSLog(@" topten[%2.2d] pop %4.4d RGBIndex %8.8d PixIndex %8.8d rgb (%d,%d,%d)",i,pop,index,pindex,red,green,blue);
    }
    
    
    
    
    //Produce results now...
    //CGPoint ttXY;
    if (hverbose) NSLog(@"Histogram Results: (sorted)");
    index = 0;
    for (i=0;i<TOPTENCOUNT;i++)
    {
        int RGBindex  = topTenLocations[i];
        int pop       = topTenPopulations[i];
        int pindex    = topTenColorIndices[i];
        red   = (RGBindex>>16) & 0xff;
        green = (RGBindex>>8)  & 0xff;
        blue  = RGBindex       & 0xff;
        row   = pindex / width1;
        col   = pindex % width1;
        //if (hverbose) NSLog(@" topten index %d",i);
        tmpc = [NSColor colorWithRed:(CGFloat)red*INV255 green:(CGFloat)green*INV255 blue:(CGFloat)blue*INV255 alpha:1];
        [topTenColors addObject:tmpc]; //Store top ten color away...
        colorx = pindex%width1;
        colory = pindex/width1;
        topTenXY[i] = CGPointMake(colorx,colory);
        //pull rgb components out
        if (hverbose && pop > 0)
        {
            NSLog(@" [%2.2d] :  pop:%5.5d colorIndex %d RGB(%3.3d,%3.3d,%3.3d) XY (%d,%d)",
                  i,pop,index,red,green,blue,row,col);
        }
    } //end for i
    
    
    free(colorzIndices);
    free(rcolorz);
    free(gcolorz);
    free(bcolorz);
    free(populations);
    free(binsIndices);
    free(binsthresh);
    free(bins);
    return;
} //end createHistogram

//=====[ColorSuggester]======================================================================
-(void) createClumps
{
    BOOL needNewClump;
    BOOL firstTime;
    int i,red,green,blue;
    int lred,lgreen,lblue;
    int rdiff,gdiff,bdiff;
    int rgbthresh = 20;  //RGB color diff?
    numClumps = 0;
    //int dataptr = 0;
    for (i=0;i<MAX_CLUMPS;i++)
    {
        clumpPtrs[i]  = -1;
        clumpSizes[i] = 0;
    }
    //OK, go through our "top ten" thresholded/sorted data and find some clumps!
    needNewClump = TRUE;
    firstTime    = TRUE;
    
    lred = lgreen = lblue = 0;
    for (i=0;i<TOPTENCOUNT;i++)
    {
        int RGBindex = topTenLocations[i];
        //int pop   = topTenPopulations[i];
        //int pindex = topTenColorIndices[i];
        red   = (RGBindex>>16) & 0xff;
        green = (RGBindex>>8)  & 0xff;
        blue  = RGBindex       & 0xff;
        if (firstTime)
        {
            lred   = red;
            lgreen = green;
            lblue  = blue;
            firstTime = FALSE;
        }
        rdiff = abs(red   - lred);
        gdiff = abs(green - lgreen);
        bdiff = abs(blue  - lblue);
        if (rdiff > rgbthresh || gdiff > rgbthresh || bdiff > rgbthresh) //Big color diff found? Next clump!
        {
            if (hverbose == 2) NSLog(@"  ...bigthresh rgbdiff %d %d %d",rdiff,gdiff,bdiff);
            numClumps++;
            needNewClump = TRUE;
        }
        else
        {
            //NSLog(@" ....incr clump %d",i);
            clumpSizes[numClumps]++;
        }
        if (needNewClump)
        {
            if (hverbose == 2) NSLog(@"  ...neednewclump %d count %d",i,numClumps);
            clumpPtrs[numClumps]  = i;
            clumpSizes[numClumps] = 1;
            lred   = red;
            lgreen = green;
            lblue  = blue;
            needNewClump = FALSE;
        }

    }
    NSLog(@"ClumpDump:");
    NSLog(@" numclumps %d",numClumps);
    for (i=0;i<numClumps;i++)
    {
        int RGBindex = topTenLocations[clumpPtrs[i]];
        red   = (RGBindex>>16) & 0xff;
        green = (RGBindex>>8)  & 0xff;
        blue  = RGBindex       & 0xff;
        int csize = clumpSizes[i];
        if (hverbose > 1 && csize > 1)
            NSLog(@" clumpptr %d size %d RGB %d,%d,%d",clumpPtrs[i],csize,red,green,blue);

    }
    
    
    
} //end createClumps

//=====[ColorSuggester]======================================================================
// Takes reduced colors and attempts to find more user-happy locations;
//  i.e. not all right on the edge of the picture....
-(void) refindColors
{
    
    int i,j;
    int red,green,blue,randx,randy,rindex,bitmapsize,tred,tgreen,tblue;
    int cArrayPtr;
    int sum1,sum2,matchToler;
    int matchX,matchY;
    NSColor *tmpc1;
    BOOL wraparound;
    BOOL gotMatch;
    const CGFloat* components;
    bitmapsize = 3*width1 * height1;
    matchToler = 15;
    int redcount = (int)[reducedColors count];
    
    for (i = 0;i < redcount; i++)
    {
        wraparound = FALSE;
        tmpc1      = [reducedColors objectAtIndex:i];
        components = CGColorGetComponents(tmpc1.CGColor);
        red        = (int)(255*components[0]);
        green      = (int)(255*components[1]);
        blue       = (int)(255*components[2]);

        randx = (int)drand(10.0,(double)width1-10.0);
        randy = (int)drand(10.0,(double)height1-10.0);
        rindex = randy * width1 + randx;
        
        cArrayPtr = rindex;
        gotMatch = FALSE;
        matchX = matchY = 0;
        //Loop over the entire thang or until we find a match
        for (j = 0 ; j < numPixels1 && !gotMatch ; j++)
        {
            //Get next color
            tred   = cArray1[cArrayPtr++];
            tgreen = cArray1[cArrayPtr++];
            tblue  = cArray1[cArrayPtr++];
            if (cArrayPtr >= bitmapsize)
            {
                cArrayPtr = 0;
                wraparound = TRUE;
            }
            //Get RGB sum of current examined pixel and match color...
            sum1 = (tred+tgreen+tblue);
            sum2 = (red + green + blue);
            if ( abs(sum1-sum2) < matchToler)
            {
                gotMatch = TRUE;
                int pixelcounter = cArrayPtr/3;
                matchX   = pixelcounter % width1;
                matchY   = pixelcounter / width1;
            }
        }
        reducedXY[i] = CGPointMake((CGFloat)matchX, (CGFloat)matchY);
        if (hverbose) NSLog(@" re-found color [%d] rgb %d %d %d matchat (%d,%d) ",i,red,green,blue,matchX,matchY);
    } //asdf
    
} //end refindColors


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
// Gets most popular color, then finds another popular color that has the farthest
//   color distance;  then repeats for 2nd most popular color
-(void) findOpposites
{
    int i,count,maxindex,middleindex,middleoppositeindex,rcount;
    BOOL found;
    float maxdist,cdist;
    float middledist,middletoler;
    NSColor *tmpc1;
    NSColor *tmpc2;

    rcount = 0;
    [reducedColors removeAllObjects];

    count = topTenColors.count;
    tmpc1 = [topTenColors objectAtIndex:0]; //Most popular color
    [reducedColors addObject:tmpc1]; //Add our color...
    reducedPopulations[rcount] = topTenPopulations[0];
    reducedXY[rcount].x = topTenXY[0].x;
    reducedXY[rcount].y = topTenXY[0].y;
    rcount++;
    NSLog(@" most popular color %@",tmpc1);
    maxdist = -999;
    maxindex = 0;
    for (i=1;i<count;i++)
    {
        tmpc2 = [topTenColors objectAtIndex:i];
        cdist = [self colorDistance:tmpc1 :tmpc2];
        //NSLog(@"   ....vs. index[%d] c2 %@ dist %f",i,tmpc2,cdist);
        if (cdist > maxdist)
        {
            maxdist  = cdist;
            maxindex = i;
        }
    } //end for i
    NSLog(@" mostpopular color %@",tmpc1);
    tmpc2 = [topTenColors objectAtIndex:maxindex];
    //Add to our reduced results...
    [reducedColors addObject:tmpc2]; //Add our opposite color...
    reducedPopulations[rcount] = topTenPopulations[maxindex];
    reducedXY[rcount].x = topTenXY[maxindex].x;
    reducedXY[rcount].y = topTenXY[maxindex].y;
    rcount++;
    NSLog(@" its opposite is[%d] %@ dist %f",maxindex,tmpc2,maxdist);
    
    //Now find "second" color... assume it will be in the "middle" of the overall color distance spread...
    found = FALSE;
    middledist = maxdist/2.0;
    middletoler = maxdist / 4.0;
    NSLog(@"median range %f to %f",middledist - middletoler, middledist + middletoler);
    int iteration = 0;
    cdist = middleindex = 0;
    while (!found)
    {
        for (i=1;i<count && !found;i++)
        {
            if (i != maxindex)
            {
                tmpc2 = [topTenColors objectAtIndex:i];
                cdist = [self colorDistance:tmpc1 :tmpc2];
                //NSLog(@"   next dist %f",cdist);
                if ((cdist > middledist-middletoler) &&  (cdist < middledist+middletoler))
                {
                    //NSLog(@" found median at %d",i);
                    middleindex = i;
                    found = TRUE;
                }
            } //end if i
        } //end for i
        if (!found) middletoler*=1.5;
        iteration++;
    } //end while !found
    if (found)
    {
        tmpc2 = [topTenColors objectAtIndex:middleindex];
        NSLog(@" after %d iters median found at index %d %@ dist %f",iteration,middleindex, tmpc2,cdist);
    }
    else //THIS IS A PROBLEM!!!
    {
        middleindex = 1;
        if (middleindex == maxindex) middleindex = 2;
        NSLog(@" no median found! assume middle at %d",middleindex);
    }
    //Add to our reduced results...
    tmpc1 = [topTenColors objectAtIndex:middleindex];
    [reducedColors addObject:tmpc1]; //Add our color...
    reducedPopulations[rcount] = topTenPopulations[middleindex];
    reducedXY[rcount].x = topTenXY[middleindex].x;
    reducedXY[rcount].y = topTenXY[middleindex].y;
    rcount++;
    
    //OK, find opposite to the "middle"...
    tmpc1 = [topTenColors objectAtIndex:middleindex];
    NSLog(@" compute opposite to middle color %@",tmpc1);
    maxdist = -999;
    middleoppositeindex = 0;
    for (i=1;i<count;i++)
    {
        if (i != maxindex && i != middleindex)
        {
            tmpc2 = [topTenColors objectAtIndex:i];
            cdist = [self colorDistance:tmpc1 :tmpc2];
            //NSLog(@"  ....vs. index[%d] c2 %@ dist %f",i,tmpc2,cdist);
            if (cdist > maxdist)
            {
                maxdist  = cdist;
                middleoppositeindex = i;
                //NSLog(@" new opposite at %d",i);
            }
        } //end if i
    } //end for i
    
    tmpc2 = [topTenColors objectAtIndex:middleoppositeindex];
    NSLog(@" middle opposite is[%d] %@ dist %f",middleoppositeindex,tmpc2,maxdist);
    [reducedColors addObject:tmpc2]; //Add our color...
    reducedPopulations[rcount] = topTenPopulations[middleoppositeindex];
    reducedXY[rcount].x = topTenXY[middleoppositeindex].x;
    reducedXY[rcount].y = topTenXY[middleoppositeindex].y;
    rcount++;

    
} //end findOpposites

//=====[ColorSuggester]======================================================================
// Takes our 'top ten' colors and reduces them; pulls colors that are
//   similar to each other out of contention... stashes results into
//   reducedColors array; we are looking for FOUR RESULTS...
-(void) reduceColors
{
    float thresh = _rgbDiffThresh; //RGB difference thresh
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
                reducedPopulations[rcount] = topTenPopulations[i];
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
        if (hverbose == 1) NSLog(@" ...reduced[%2d] (%3.3d,%3.3d,%3.3d) : %5.2f,%5.2f pop: %d",i,red,green,blue,reducedXY[i].x,reducedXY[i].y,reducedPopulations[i]);
    }
    NSLog(@" ...found %d reduced colors",(int)reducedColors.count);
}  //end reduceColors

//=====[ColorSuggester]======================================================================
-(int) getReducedCount
{
    return (int)reducedColors.count;
}  //end getReducedCount

//=====[ColorSuggester]======================================================================
-(CGPoint) getNthReducedXY : (int) n
{
    if (n < 0 || n >= [reducedColors count]) return CGPointMake(0, 0);
    //if (hverbose) NSLog(@" get reducedXY %f,%f",reducedXY[n].x,reducedXY[n].y);
    return reducedXY[n];
} //end getNthPopularXY


//=====[ColorSuggester]======================================================================
-(NSColor *) getNthReducedColor: (int) n
{
    if (n < 0 || n >= [reducedColors count]) return [NSColor blackColor];
    //if (hverbose) NSLog(@" get reducedColor %@",[reducedColors objectAtIndex:n]);
    return [reducedColors objectAtIndex:n];
} //end getNthPopularCooor

//=====[ColorSuggester]======================================================================
-(int) getNthReducedPopulation : (int) n
{
    if (n < 0 || n >= [reducedColors count]) return 0;
    return reducedPopulations[n];
}



//=====[ColorSuggester]======================================================================
-(float) colorDistance : (NSColor *)c1 : (NSColor *) c2
{
    float distance = 0.0;
    float rdel,gdel,bdel;
    const CGFloat* components1;
    const CGFloat* components2;
    components1 = CGColorGetComponents(c1.CGColor);
    components2 = CGColorGetComponents(c2.CGColor);
    rdel = components1[0] - components2[0];
    gdel = components1[1] - components2[1];
    bdel = components1[2] - components2[2];
    distance = sqrtf( rdel*rdel + gdel*gdel + bdel*bdel);
    return distance;
} //end colorDistance



//=====[ColorSuggester]======================================================================
-(void) dump
{
    int i,red,green,blue;
    NSColor *tmpc1;
    const CGFloat* components;
    return;
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
    NSLog(@"   reduced, found %d colors", (int)reducedColors.count);
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

//=====[ColorSuggester]======================================================================
-(NSString *) getAlgoDesc
{
    NSString *nada = @"no description";
    if (_whichAlgo == ALGO_HISTOGRAM)
    {
        return histDesc;
    }
    if (_whichAlgo == ALGO_OPPOSITE12)
    {
        return opposite12Desc;
    }
    return nada;
} //end getAlgoDesc


/*-----------------------------------------------------------*/
/*-----------------------------------------------------------*/
double drand(double lo_range,double hi_range )
{
    int rand_int;
    double tempd,outd;
    
    rand_int = rand();
    tempd = (double)rand_int/(double)RAND_MAX;  /* 0.0 <--> 1.0*/
    
    outd = (double)(lo_range + (hi_range-lo_range)*tempd);
    return(outd);
}   //end drand


@end
