//
//   _   _ ____  _  ______                           _
//  | | | |  _ \| |/ / ___| ___ _ __   ___ _ __ __ _| |_ ___
//  | |_| | | | | ' / |  _ / _ \ '_ \ / _ \ '__/ _` | __/ _ \
//  |  _  | |_| | . \ |_| |  __/ | | |  __/ | | (_| | ||  __/
//  |_| |_|____/|_|\_\____|\___|_| |_|\___|_|  \__,_|\__\___|
//
//  HDKGenerate (pulled from HDKGenerator)
//  HuedokuPix
//
//  NOTE:    This version is similar to but different from the iOS
//            version, be careful cross-integrating!
//
//  Created by Dave Scruton on 8/1/15.
//  Copyright (c) 2015 huedoku, inc. All rights reserved.
//  DHS 8/5/15: Pulled in HDK relative luminance calculations..
//  DHS 8/11/15: Zach change to reference array creation
//  DHS 8/19/15: pulled "const" from component vars
//               moved c[][] array out of generate subroutine
#import "HDKCGenerate.h"


@implementation HDKCGenerate

BOOL goodPuzzle = TRUE; //ZST: this is for colorChecker in generateZachArray
#define INV255 0.00392156
#define R_INDEX 0
#define G_INDEX 1
#define B_INDEX 2
#define L_INDEX 0
#define A_INDEX 1


//=====<HDKGenerate>======================================================================
// Just clears our our object...
-(instancetype) init
{
    //DHS 8/19 Make sure init goes thru before setting up..
    if (self = [super init])
    {
        _xsize      = BIGGEST_PUZZLE;
        _ysize      = BIGGEST_PUZZLE;
        _difficulty = 1;
        //Init tile (CLUT) colors
        for(int loop=0;loop<_xsize*_ysize;loop++)
        {
            colorz[loop] = [NSColor blackColor];
        }
        //Init our four corner colors...
        _tlColor = [NSColor blackColor];
        _trColor = [NSColor blackColor];
        _blColor = [NSColor blackColor];
        _brColor = [NSColor blackColor];
        
        _HCval = 0.0;
        _LPval = 0.0;
        _RGval = 0.0;
        _YBval = 0.0;
        
        referenceArrayUp = 0;
        _HCval = 0.0;
        _LPval = 0.0;
        _RGval = 0.0;
        _YBval = 0.0;
        
        inv255 = 1.0/255.0;
        
        LABtlcorner = [[NSArray alloc] init];
        LABtrcorner = [[NSArray alloc] init];
        LABblcorner = [[NSArray alloc] init];
        LABbrcorner = [[NSArray alloc] init];
        LAB         = [[NSArray alloc] init];

    }

    return self;
} //end init

//=====<HDKGenerate>======================================================================
-(void) setColor : (int) which : (NSColor *) color
{
    if (which < 0 || which > MAX_HDKGEN_COLORS) return;
    colorz[which] = color;
}

//=====<HDKGenerate>======================================================================
-(NSColor *) getColor: (int) which
{
    if (which < 0 || which > MAX_HDKGEN_COLORS) return [NSColor blackColor];
    NSColor *result;
    double rf,gf,bf;
    rf = finalColorz[which][R_INDEX];
    gf = finalColorz[which][G_INDEX];
    bf = finalColorz[which][B_INDEX];
    //NSLog(@" getcolor [%d] %f %f %f",which,rf,gf,bf);
    result = [NSColor colorWithRed: rf*inv255 green:gf*inv255 blue:bf*inv255 alpha:1.0];
    
    return result;
}
//=====<HDKGenerate>======================================================================
-(NSColor *) getColorOLD: (int) which
{
    if (which < 0 || which > MAX_HDKGEN_COLORS) return [NSColor blackColor];
    return colorz[which];
}

//===HDKGenerator===================================================================
-(void) getColorComponents
{
    //Components are 0.0 -> 1.0 range
    tlcomponents = CGColorGetComponents(_tlColor.CGColor);
    trcomponents = CGColorGetComponents(_trColor.CGColor);
    blcomponents = CGColorGetComponents(_blColor.CGColor);
    brcomponents = CGColorGetComponents(_brColor.CGColor);

}


//===HDKGenerator===================================================================
-(void) generateZachArray
{
    double tlr,tlg,tlb;
    double trr,trg,trb;
    double blr,blg,blb;
    double brr,brg,brb;
    
    //NSLog(@" Zach---------------------------------------------------------");
    
    //input length of side
    int length = _xsize;
    //DHS 8/19 made c[][] global to save on stack...
    NSColor* c[length][length];
    
    [self getColorComponents];
    
    //OK, break up hex inputs to rgb components, double 0-255
    //    components1[0],components1[1],components1[2],components1[3],(int)p1.x,(int)p1.y,_colorName1);
    
    tlr = (double)(255.0 * tlcomponents[0]);
    tlg = (double)(255.0 * tlcomponents[1]);
    tlb = (double)(255.0 * tlcomponents[2]);
    trr = (double)(255.0 * trcomponents[0]);
    trg = (double)(255.0 * trcomponents[1]);
    trb = (double)(255.0 * trcomponents[2]);
    blr = (double)(255.0 * blcomponents[0]);
    blg = (double)(255.0 * blcomponents[1]);
    blb = (double)(255.0 * blcomponents[2]);
    brr = (double)(255.0 * brcomponents[0]);
    brg = (double)(255.0 * brcomponents[1]);
    brb = (double)(255.0 * brcomponents[2]);
    
   //Create our corner colors from inputs...
    c[0][0]               = [NSColor colorWithRed: inv255*tlr   green : inv255*tlg   blue : inv255*tlb   alpha:1.0];    //upper left corner = BLACK
    c[0][length-1]        = [NSColor colorWithRed: inv255*trr   green : inv255*trg   blue : inv255*trb   alpha:1.0];    //upper left corner = BLACK
    c[length-1][0]        = [NSColor colorWithRed: inv255*blr   green : inv255*blg   blue : inv255*blb   alpha:1.0];    //upper left corner = BLACK
    c[length-1][length-1] = [NSColor colorWithRed: inv255*brr   green : inv255*brg   blue : inv255*brb   alpha:1.0];    //upper left corner = BLACK
    
    ///CRASH ABOVE HERE
    //get LAB values for each corner
    [self getLAB:c[0][0]];
    LABtlcorner = LAB;
    [self getLAB:(c[0][length-1])];
    LABtrcorner = LAB;
    [self getLAB:(c[length-1][0])];
    LABblcorner = LAB;
    [self getLAB:(c[length-1][length-1])];
    LABbrcorner = LAB;
    
    //    return;
    
    
    //    LABtlcorner = [NSMutableArray arrayWithArray:[self getLAB:c[0][0]]];
    //    LABtrcorner = [NSMutableArray arrayWithArray:[self getLAB:(c[0][length-1])]];;
    //    LABblcorner = [NSMutableArray arrayWithArray:[self getLAB:(c[length-1][0])]];;
    //    LABbrcorner = [NSMutableArray arrayWithArray:[self getLAB:(c[length-1][length-1])]];;
    
    
    double LABluminanceA = fabs([LABtlcorner[1] doubleValue])+fabs([LABtrcorner[1] doubleValue])
    +fabs([LABblcorner[1] doubleValue])+fabs([LABbrcorner[1] doubleValue]);
    
    double LABluminanceB = fabs([LABtlcorner[2] doubleValue])+fabs([LABtrcorner[2] doubleValue])
    +fabs([LABblcorner[2] doubleValue])+fabs([LABbrcorner[2] doubleValue]);
    //DHS need to fill in...?
    _RGval = LABluminanceA/4.0;
    _YBval = LABluminanceB/4.0;
    
    _LPval = [self getRelativeLuminance];
    _HCval = 1.0 - _LPval;
    //NSLog(@"RG/YB HC/LP: %f/%f %f/%f ",_RGval,_YBval,_LPval,_HCval);
    
    
    //get left column
    for(int i = 1; i<length-1; i++)
    {
        c[i][0] = [self solve : c[0][0] : c[length-1][0] : i : length];
    }
    
    //get right column
    for(int i = 1; i<length-1; i++)
    {
        c[i][length-1] = [self solve : c[0][length-1] : c[length-1][length-1] : i : length];
    }
    
    //get all rows
    for(int row = 0; row<length; row++)
    {
        for(int col = 1; col<length-1; col++)
        {
            c[row][col] = [self solve : c[row][0] : c[row][length-1] : col : length];
        }
        
    }
    
    
    
    //Populate HDKGen array with results...
    int cptr = 0;
    for(int row = 0; row<length; row++){
        for(int col = 0; col<length; col++)
        {
            rgbcomponents = CGColorGetComponents(c[row][col].CGColor);
            rgbarray[row][col][0] = (int)(255.0 * rgbcomponents[0]);
            rgbarray[row][col][1] = (int)(255.0 * rgbcomponents[1]);
            rgbarray[row][col][2] = (int)(255.0 * rgbcomponents[2]);
            colorz[cptr] = c[row][col];
            cptr++;
        }
    }
    
    
    //print data
//        for(int row = 0; row<length; row++){
//            for(int col = 0; col<length; col++)
//            {
//                NSLog(@" Tile: [%d][%d] : RGB %d %d %d",row,col,
//                      rgbarray[row][col][0],
//                      rgbarray[row][col][1],
//                      rgbarray[row][col][2]
//                      );
//    
//            }
//        }

    //colorChecker start
    int sensitivityRGB = 16; //increase to make colorChecker identify bad puzzles more easily
    int sensitivitySUM = 31; //increase to make colorChecker identify bad puzzles more easily
    goodPuzzle = true;
    NSColor* tempo;
    
    for(int row = 0; row<length; row++){
        for(int col = 0; col<length; col++){
            
            tempo = c[row][col];
            const CGFloat* tempocomponents;
            tempocomponents = CGColorGetComponents(tempo.CGColor);
            float tr,tg,tb;
            tr = tempocomponents[0];
            tg = tempocomponents[1];
            tb = tempocomponents[2];
            
            for(int i = row; i<length; i++){
                int x;
                if(i == row){
                    x = col + 1;
                }
                else{
                    x = 0;
                }
                for(int j = x; j<length; j++)
                {
                    const CGFloat* cixcomponents;
                    cixcomponents = CGColorGetComponents(c[i][x].CGColor);
                    float cr,cg,cb;
                    cr = cixcomponents[0];
                    cg = cixcomponents[1];
                    cb = cixcomponents[2];
                    //NSLog(@" ij %d %d trgb %f %f %f vs crgb %f %f %f",i,j,tr,tg,tb,cr,cg,cb);
                    if ((fabs(255.0*tr - 255.0*cr)<sensitivityRGB)
                        && (fabs(255.0*tb - 255.0*cb)<sensitivityRGB)
                        && (fabs(255.0*tg - 255.0*cg)<sensitivityRGB)
                        && (fabs(255.0*tr - 255.0*cr) + fabs(255.0*tb - 255.0*cb) + fabs(255.0*tg - 255.0*cg))/3<sensitivitySUM)
                    {
                        goodPuzzle = false;
                        //NSLog(@"did I get here?");
                        break;
                    }
                } //end j loop
            }    //end i loop
        }       //end col loop
    }          //end row loop
    
    //end colorChecker
    
} //end generateZachArray


//===HDKGenerator===================================================================
-(void) generateZachArray2
{
    double tlr,tlg,tlb;
    double trr,trg,trb;
    double blr,blg,blb;
    double brr,brg,brb;
    int cptr0,cptr1;
    double ar,ag,ab,br,bg,bb;
    //NSLog(@" Zach22");
    //input length of side
    int length = _xsize;

    //Simple color array, 2D RGB: This gets "popped" off the stack
    //   when this routine exits; NO LEAKS!!
    double colorz2d[length][length][3];
    
    //Components are 0.0 -> 1.0 range
    tlcomponents = CGColorGetComponents(_tlColor.CGColor);
    trcomponents = CGColorGetComponents(_trColor.CGColor);
    blcomponents = CGColorGetComponents(_blColor.CGColor);
    brcomponents = CGColorGetComponents(_brColor.CGColor);

    //OK, break up hex inputs to rgb components, double 0-255
    //    components1[0],components1[1],components1[2],components1[3],(int)p1.x,(int)p1.y,_colorName1);

    tlr = (double)(255.0 * tlcomponents[0]);
    tlg = (double)(255.0 * tlcomponents[1]);
    tlb = (double)(255.0 * tlcomponents[2]);
    trr = (double)(255.0 * trcomponents[0]);
    trg = (double)(255.0 * trcomponents[1]);
    trb = (double)(255.0 * trcomponents[2]);
    blr = (double)(255.0 * blcomponents[0]);
    blg = (double)(255.0 * blcomponents[1]);
    blb = (double)(255.0 * blcomponents[2]);
    brr = (double)(255.0 * brcomponents[0]);
    brg = (double)(255.0 * brcomponents[1]);
    brb = (double)(255.0 * brcomponents[2]);
    //NSLog(@" tlrgb %f %f %f",tlr,tlg,tlb);
    //NSLog(@" trrgb %f %f %f",trr,trg,trb);
    //NSLog(@" blrgb %f %f %f",blr,blg,blb);
    //NSLog(@" brrgb %f %f %f",brr,brg,brb);

    //input RGB values for corners
    //    c[0][0]               = [NSColor colorWithRed:0   green:0   blue:0   alpha:1.0];    //upper left corner = BLACK
    //    c[0][length-1]        = [NSColor colorWithRed:1.0 green:0   blue:0   alpha:1.0];   //upper right corner = RED
    //    c[length-1][0]        = [NSColor colorWithRed:0   green:0   blue:1.0 alpha:1.0];  //lower left corner   = BLUE
    //    c[length-1][length-1] = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]; //lower right corner   = WHITE
    
    //Create our corner colors from inputs... stored as 0..1 range
    cptr0 = 0;
    cptr1 = 0;
    colorz2d[cptr0][cptr1][R_INDEX] = inv255*tlr;
    colorz2d[cptr0][cptr1][G_INDEX] = inv255*tlg;
    colorz2d[cptr0][cptr1][B_INDEX] = inv255*tlb;
    cptr1 = length-1;
    colorz2d[cptr0][cptr1][R_INDEX] = inv255*trr;
    colorz2d[cptr0][cptr1][G_INDEX] = inv255*trg;
    colorz2d[cptr0][cptr1][B_INDEX] = inv255*trb;
    cptr0 = length-1;
    cptr1 = 0;
    colorz2d[cptr0][cptr1][R_INDEX] = inv255*blr;
    colorz2d[cptr0][cptr1][G_INDEX] = inv255*blg;
    colorz2d[cptr0][cptr1][B_INDEX] = inv255*blb;
    cptr1 = length-1;
    colorz2d[cptr0][cptr1][R_INDEX] = inv255*brr;
    colorz2d[cptr0][cptr1][G_INDEX] = inv255*brg;
    colorz2d[cptr0][cptr1][B_INDEX] = inv255*brb;
    
//    c[0][0]               = [NSColor colorWithRed: inv255*tlr   green : inv255*tlg   blue : inv255*tlb   alpha:1.0];    //upper left corner = BLACK
//    c[0][length-1]        = [NSColor colorWithRed: inv255*trr   green : inv255*trg   blue : inv255*trb   alpha:1.0];    //upper left corner = BLACK
//    c[length-1][0]        = [NSColor colorWithRed: inv255*blr   green : inv255*blg   blue : inv255*blb   alpha:1.0];    //upper left corner = BLACK
//    c[length-1][length-1] = [NSColor colorWithRed: inv255*brr   green : inv255*brg   blue : inv255*brb   alpha:1.0];    //upper left corner = BLACK

    ///CRASH ABOVE HERE
    //get LAB values for each corner
    cptr0 = 0;
    cptr1 = 0;
    [self getLAB2 : colorz2d[cptr0][cptr1][R_INDEX] : colorz2d[cptr0][cptr1][G_INDEX] : colorz2d[cptr0][cptr1][B_INDEX]       ];
    LABtl_Array[L_INDEX] = LAB_Array[L_INDEX];
    LABtl_Array[A_INDEX] = LAB_Array[A_INDEX];
    LABtl_Array[B_INDEX] = LAB_Array[B_INDEX];
    cptr0 = 0;
    cptr1 = length-1;
    [self getLAB2 : colorz2d[cptr0][cptr1][R_INDEX] : colorz2d[cptr0][cptr1][G_INDEX] : colorz2d[cptr0][cptr1][B_INDEX]       ];
    LABtr_Array[L_INDEX] = LAB_Array[L_INDEX];
    LABtr_Array[A_INDEX] = LAB_Array[A_INDEX];
    LABtr_Array[B_INDEX] = LAB_Array[B_INDEX];
    cptr0 = length-1;
    cptr1 = 0;
    [self getLAB2 : colorz2d[cptr0][cptr1][R_INDEX] : colorz2d[cptr0][cptr1][G_INDEX] : colorz2d[cptr0][cptr1][B_INDEX]       ];
    LABbl_Array[L_INDEX] = LAB_Array[L_INDEX];
    LABbl_Array[A_INDEX] = LAB_Array[A_INDEX];
    LABbl_Array[B_INDEX] = LAB_Array[B_INDEX];
    cptr0 = length-1;
    cptr1 = length-1;
    [self getLAB2 : colorz2d[cptr0][cptr1][R_INDEX] : colorz2d[cptr0][cptr1][G_INDEX] : colorz2d[cptr0][cptr1][B_INDEX]       ];
    LABbr_Array[L_INDEX] = LAB_Array[L_INDEX];
    LABbr_Array[A_INDEX] = LAB_Array[A_INDEX];
    LABbr_Array[B_INDEX] = LAB_Array[B_INDEX];

    double LABluminanceA = fabs(LABtl_Array[A_INDEX])+fabs(LABtr_Array[A_INDEX])
                          +fabs(LABbl_Array[A_INDEX])+fabs(LABbr_Array[A_INDEX]);
    
    double LABluminanceB = fabs(LABtl_Array[B_INDEX])+fabs(LABtr_Array[B_INDEX])
                          +fabs(LABbl_Array[B_INDEX])+fabs(LABbr_Array[B_INDEX]);
    //DHS need to fill in...?
    _RGval = LABluminanceA/4.0;
    _YBval = LABluminanceB/4.0;
    
    
    _LPval = [self getRelativeLuminance];
    _HCval = 1.0 - _LPval;
    //NSLog(@"RG/YB HC/LP: %f/%f %f/%f ",_RGval,_YBval,_LPval,_HCval);


    //get left column
    for(int i = 1; i<length-1; i++)
    {
        cptr0 = 0;
        cptr1 = 0;
        ar = colorz2d[cptr0][cptr1][R_INDEX];
        ag = colorz2d[cptr0][cptr1][G_INDEX];
        ab = colorz2d[cptr0][cptr1][B_INDEX];
        cptr0 = length-1;
        cptr1 = 0;
        br = colorz2d[cptr0][cptr1][R_INDEX];
        bg = colorz2d[cptr0][cptr1][G_INDEX];
        bb = colorz2d[cptr0][cptr1][B_INDEX];
        [self solve2 : ar : ag : ab : br : bg : bb : i : length];
        colorz2d[i][0][R_INDEX] = solvedRGB[R_INDEX];
        colorz2d[i][0][G_INDEX] = solvedRGB[G_INDEX];
        colorz2d[i][0][B_INDEX] = solvedRGB[B_INDEX];
        //NSLog(@" i %d solved %f %f %f",i,solvedRGB[R_INDEX],solvedRGB[G_INDEX],solvedRGB[B_INDEX]);
        //    { c[i][0] = [self solve : c[0][0] : c[length-1][0] : i : length]; }
    }

    //get right column
    for(int i = 1; i<length-1; i++)
    {
        cptr0 = 0;
        cptr1 = length-1;
        ar = colorz2d[cptr0][cptr1][R_INDEX];
        ag = colorz2d[cptr0][cptr1][G_INDEX];
        ab = colorz2d[cptr0][cptr1][B_INDEX];
        cptr0 = length-1;
        cptr1 = length-1;
        br = colorz2d[cptr0][cptr1][R_INDEX];
        bg = colorz2d[cptr0][cptr1][G_INDEX];
        bb = colorz2d[cptr0][cptr1][B_INDEX];
        [self solve2 : ar : ag : ab : br : bg : bb : i : length];
        colorz2d[i][length-1][R_INDEX] = solvedRGB[R_INDEX];
        colorz2d[i][length-1][G_INDEX] = solvedRGB[G_INDEX];
        colorz2d[i][length-1][B_INDEX] = solvedRGB[B_INDEX];
        //NSLog(@" i2 %d solved %f %f %f",i,solvedRGB[R_INDEX],solvedRGB[G_INDEX],solvedRGB[B_INDEX]);
        //{ c[i][length-1] = [self solve : c[0][length-1] : c[length-1][length-1] : i : length]; }
    }

    //get all rows...
    for(int row = 0; row<length; row++)
    {
        for(int col = 1; col<length-1; col++)
        {
            cptr0 = row;
            cptr1 = 0;
            ar = colorz2d[cptr0][cptr1][R_INDEX];
            ag = colorz2d[cptr0][cptr1][G_INDEX];
            ab = colorz2d[cptr0][cptr1][B_INDEX];
            cptr0 = row;
            cptr1 = length-1;
            br = colorz2d[cptr0][cptr1][R_INDEX];
            bg = colorz2d[cptr0][cptr1][G_INDEX];
            bb = colorz2d[cptr0][cptr1][B_INDEX];
            [self solve2 : ar : ag : ab : br : bg : bb : col : length];
            colorz2d[row][col][R_INDEX] = solvedRGB[R_INDEX];
            colorz2d[row][col][G_INDEX] = solvedRGB[G_INDEX];
            colorz2d[row][col][B_INDEX] = solvedRGB[B_INDEX];
            //NSLog(@" irc %d,%d solved %f %f %f",row,col,solvedRGB[R_INDEX],solvedRGB[G_INDEX],solvedRGB[B_INDEX]);

            // { c[row][col] = [self solve : c[row][0] : c[row][length-1] : col : length]; }
        }
    }
    
    
    //Populate HDKGen array with results...
    int cptr = 0;
    for(int row = 0; row<length; row++){
        for(int col = 0; col<length; col++)
        {
            //rgbcomponents = CGColorGetComponents(c[row][col].CGColor);
            ar =  colorz2d[row][col][R_INDEX] ;
            ag =  colorz2d[row][col][G_INDEX] ;
            ab =  colorz2d[row][col][B_INDEX] ;
            
            rgbarray[row][col][R_INDEX] = (int)(255.0 * ar);
            rgbarray[row][col][G_INDEX] = (int)(255.0 * ag);
            rgbarray[row][col][B_INDEX] = (int)(255.0 * ab);
            //NSLog(@" final(%d,%d): %f %f %f",row,col,ar,ag,ab);
            finalColorz[cptr][R_INDEX] = rgbarray[row][col][R_INDEX];
            finalColorz[cptr][G_INDEX] = rgbarray[row][col][G_INDEX];
            finalColorz[cptr][B_INDEX] = rgbarray[row][col][B_INDEX];
            cptr++;
        }
    }
    
    
    //print data
//    for(int row = 0; row<length; row++){
//        for(int col = 0; col<length; col++)
//        {
//            NSLog(@" Tile: [%d][%d] : RGB %d %d %d",row,col,
//                  rgbarray[row][col][R_INDEX],
//                  rgbarray[row][col][G_INDEX],
//                  rgbarray[row][col][B_INDEX]
//                  );
//            
//        }
//    }
//    for (int i=0;i<length*length;i++)
//    {
//        NSLog(@" fc[%d] rgb %f %f %f",i,finalColorz[i][R_INDEX],finalColorz[i][G_INDEX],finalColorz[i][B_INDEX]);
//    }
    
    //colorChecker start
    int sensitivityRGB = 16; //increase to make colorChecker identify bad puzzles more easily
    int sensitivitySUM = 31; //increase to make colorChecker identify bad puzzles more easily
    goodPuzzle = true;
    
    for(int row = 0; row<length; row++){
        for(int col = 0; col<length; col++){

            float tr,tg,tb; //WE want rgb to be 0..1 range!
            tr = colorz2d[row][col][R_INDEX];
            tg = colorz2d[row][col][G_INDEX];
            tb = colorz2d[row][col][B_INDEX];
            
            for(int i = row; i<length; i++){
                int x;
                if(i == row){
                    x = col + 1;
                }
                else{
                    x = 0;
                }
                for(int j = x; j<length; j++)
                {
                    double cr,cg,cb;
                    cr = colorz2d[i][x][R_INDEX];
                    cg = colorz2d[i][x][G_INDEX];
                    cb = colorz2d[i][x][B_INDEX];
                    //NSLog(@" ij %d %d trgb %f %f %f vs crgb %f %f %f",i,j,tr,tg,tb,cr,cg,cb);
                    if (   (fabs(255.0*tr - 255.0*cr)<sensitivityRGB)
                        && (fabs(255.0*tb - 255.0*cb)<sensitivityRGB)
                        && (fabs(255.0*tg - 255.0*cg)<sensitivityRGB)
                        && (fabs(255.0*tr - 255.0*cr) + fabs(255.0*tb - 255.0*cb) + fabs(255.0*tg - 255.0*cg))/3<sensitivitySUM)
                    {
                        goodPuzzle = false;
                        //NSLog(@"BAD PUZZLE????");
                        break;
                    }
                } //end j loop
            }    //end i loop
        }       //end col loop
    }          //end row loop
    
    //end colorChecker
    
} //end generateZachArray2



//======(Hue-Do-Ku)==========================================
// This uses the four corner colors... (globals)
-(float) getRelativeLuminance
{
    double rellum = 0.0;
    //double relz[36];
    double hmax,hmin;
    //int psx,psy; //,rr,gg,bb;
    //psx = _xsize;
    //psy = _ysize;
    
    NSColor  *corner[] = {_tlColor,_trColor,_blColor,_brColor};

    hmin = 999.0;
    hmax = -999.0;
    for(int i = 0;i<4;i++)
    {
        const CGFloat* components;
        double tl = 0.0f;
        double Rd,Gd,Bd;
        double rsRGB,gsRGB,bsRGB;
        components = CGColorGetComponents(corner[i].CGColor);
        rsRGB = (double)components[0];
        gsRGB = (double)components[1];
        bsRGB = (double)components[2];
        //NSLog(@" rl[%d] rgb %f %f %f",i,rsRGB,gsRGB,bsRGB);
        if (rsRGB <= 0.03928) Rd = rsRGB/12.92;
        else                  Rd = pow(((rsRGB + 0.055) / 1.055), 2.4);
        
        if (gsRGB <= 0.03928) Gd = gsRGB/12.92;
        else                  Gd = pow(((gsRGB + 0.055) / 1.055), 2.4);
        
        if (bsRGB <= 0.03928) Bd = bsRGB/12.92;
        else                  Bd = pow(((bsRGB + 0.055) / 1.055), 2.4);
        
        //NSLog(@"      RDZ %f %f %f",Rd,Gd,Bd);
        
        tl = (0.2126 * Rd) + (0.7152 * Gd) + (0.0722 * Bd);
        //NSLog(@"      TL %f",tl);
        if (tl < hmin) hmin = tl;
        if (tl > hmax) hmax = tl;
    }
    //NSLog(@" Max %f Min %f",hmax,hmin);
    rellum = (hmax-hmin);
    //NSLog(@" FINAL LUM %f",rellum);
    
    return (float)rellum;
} //end getRelativeLuminance



//===HDKGenerator===================================================================
// written by zach...
//   searches through array to find correspoding color values
- (int) search : (double) target : (double *) array : (int) arraysize
{
    double temp = 1000;
    double temp2 = 1000;
    int index = -1;
    for(int i = 0; i<arraysize; i++)
    {
        temp = fabs(array[i]-target);
        if(temp<temp2)
        { temp2 = temp; index = i; }
        
    }
    //NSLog(@" ...search t %f found %d",target,index);
    return index;
}

//===HDKGenerator===================================================================
//Creates a reference array of all possible color values between 0 and 256
-(void) initReferenceArray
{
    for(int i = 0; i<MAX_REF_ARRAY; i++)
    { referenceArray[i]=-1; }
    
    referenceArray[0] = 0;
    referenceArray[MAX_REF_ARRAY-1] = 256;
    while(referenceArray[MAX_REF_ARRAY-2]<0)
    {
        double tempArray[2]  = {-1, -1};
        double tempArray2[2] = {-1, -1};
        for(int i = 0; i<MAX_REF_ARRAY; i++)
        {
            if(i==MAX_REF_ARRAY-1)
            { tempArray[1]  = referenceArray[i];
                tempArray2[1] = i;
                int temp      = (int)((tempArray2[0]+tempArray2[1])/2);
                referenceArray[temp]   = sqrt((tempArray[0]*tempArray[0]+tempArray[1]*tempArray[1])/(2));
                tempArray[0]  = -1;
                tempArray[1]  = -1;
                tempArray2[0] = -1;
                tempArray2[1] = -1;
                break;  //DHS Huh? why do we need this?
            }
            
            else
            {
                if(referenceArray[i]>=0 && referenceArray[i+1]<0)
                {
                    if(tempArray[0]<0)
                    { tempArray[0] = referenceArray[i]; tempArray2[0] = i; }
                    
                    else
                    { tempArray[1] = referenceArray[i]; tempArray2[1] = i;
                        int temp = (int)((tempArray2[0]+tempArray2[1])/2);
                        referenceArray[temp] = sqrt((tempArray[0]*tempArray[0]+tempArray[1]*tempArray[1])/(2));
                        tempArray[0] = -1;
                        tempArray[1] = -1;
                        tempArray2[0] = -1;
                        tempArray2[1] = -1;
                        break;   //Why is a break at the bottom of an if, does this break from the i loop?
                    }
                } //end if array
            }   //end outer else
        } //end for i
    }//end while making ref arr
    
    //Zach change 8/10: edited for television
    double x=0;
    double coeff1 = 0.3/3.0;
    double coeff2 = 2.7/3.0;
    for (int i=0; i<MAX_REF_ARRAY;i++)
    {
        x=(double)i/255.0;
        referenceArray[i] = (((referenceArray[i]*(coeff1+x)) + (double)i*(coeff2-x)));
    }
    
    int dumpref = 0;
    if (dumpref)
    {
        for (int j=0;j<MAX_REF_ARRAY;j++)
        {
            NSLog(@" ..referenceArray[%d] %f",j,referenceArray[j]);
        }
    }
    
} //end initReferenceArray

//===HDKGenerator===================================================================
// written by zach...: we're not really sure what it 'solves' yet...
//DHS PLS CHECK REHOST WORK!
-(NSColor *) solve : (NSColor *)a : (NSColor *) b : (int) pos : (int) length
{
    //    public Color solve(Color a, Color b, int pos, int length){
    //double inv255 = 1.0/255.0;
    
    if (!referenceArrayUp)  //Dirty global
    {
        [self initReferenceArray]; //sets up more dirty globals!
        referenceArrayUp = 1;
    }
    
    double R;
    double G;
    double B;
    const CGFloat* acomponents;
    const CGFloat* bcomponents;
    acomponents = CGColorGetComponents(a.CGColor);
    bcomponents = CGColorGetComponents(b.CGColor);
    
    double ared   = 255.0*(double)acomponents[0];
    double agreen = 255.0*(double)acomponents[1];
    double ablue  = 255.0*(double)acomponents[2];
    double bred   = 255.0*(double)bcomponents[0];
    double bgreen = 255.0*(double)bcomponents[1];
    double bblue  = 255.0*(double)bcomponents[2];
    
    double rRange    = (double)abs([self search : ared : referenceArray : MAX_REF_ARRAY] - [self search : bred : referenceArray : MAX_REF_ARRAY] );//diff between reds
    double rInterval = rRange/(double)(length-1);
    
    
//    NSLog(@" solve tp 1 argb %f %f %f brgb %f %f %f rrange/interval %f %f",
//          ared,agreen,ablue,bred,bgreen,bblue,rRange,rInterval);
    if( ared <= bred)
    { R = referenceArray[(int) [self search : ared : referenceArray : MAX_REF_ARRAY] + (int)(rInterval*pos) ]; } //DHS does (int)rInterval... round correctly?
    
    else
    {   int pos1 = length - pos - 1;
        R = referenceArray[(int) [self search : bred : referenceArray : MAX_REF_ARRAY] + (int)(rInterval*pos1) ]; }
    
    double gRange    = (double)abs([self search : agreen : referenceArray : MAX_REF_ARRAY] - [self search : bgreen : referenceArray : MAX_REF_ARRAY]);
    double gInterval = gRange/(double)(length-1);
    if(agreen<=bgreen)
    {
        G = referenceArray[(int)([self search : agreen : referenceArray : MAX_REF_ARRAY] + (int)(gInterval*pos) )];
    }
    
    else
    {   int pos2 = length - pos - 1;
        G = referenceArray[(int)([self search : bgreen : referenceArray : MAX_REF_ARRAY] + (int)(gInterval*pos2) )];}
    
    double bRange    = (double)abs([self search : ablue : referenceArray : MAX_REF_ARRAY] - [self search : bblue : referenceArray : MAX_REF_ARRAY]);
    double bInterval = bRange/(double)(length-1);
    if(ablue <= bblue)
    { B = referenceArray[(int)[self search : ablue : referenceArray : MAX_REF_ARRAY] + (int)(bInterval*pos) ]; }
    
    else
    {   int pos3 = length - pos - 1;
        B = referenceArray[(int)([self search : bblue : referenceArray : MAX_REF_ARRAY] + (int)(bInterval*pos3) )]; }
    R = round(R);
    G = round(G);
    B = round(B);
   // NSLog(@" solve RGB %f %f %f",R,G,B);
    return [NSColor colorWithRed:R*inv255 green:G*inv255 blue:B*inv255 alpha:1.0];
} //end solve



//===HDKGenerator===================================================================
// written by zach...
//DHS PLS CHECK REHOST WORK!
-(void) solve2 : (double) ar : (double) ag : (double) ab : (double) br : (double) bg : (double) bb : (int) pos : (int) length
{
    //    public Color solve(Color a, Color b, int pos, int length){
    //double inv255 = 1.0/255.0;
    
    if (!referenceArrayUp)  //Dirty global
    {
        [self initReferenceArray]; //sets up more dirty globals!
        referenceArrayUp = 1;
    }
    
    double R;
    double G;
    double B;
 
    double ared   = 255.0*ar;
    double agreen = 255.0*ag;
    double ablue  = 255.0*ab;
    double bred   = 255.0*br;
    double bgreen = 255.0*bg;
    double bblue  = 255.0*bb;
    
    double rRange    = (double)abs([self search : ared : referenceArray : MAX_REF_ARRAY] - [self search : bred : referenceArray : MAX_REF_ARRAY] );//diff between reds
    double rInterval = rRange/(double)(length-1);
    
//    NSLog(@" solve tp 1 argb %f %f %f brgb %f %f %f rrange/interval %f %f",
//          ared,agreen,ablue,bred,bgreen,bblue,rRange,rInterval);

    if( ared <= bred)
    { R = referenceArray[(int) [self search : ared : referenceArray : MAX_REF_ARRAY] + (int)(rInterval*pos) ]; } //DHS does (int)rInterval... round correctly?
    
    else
    {   int pos1 = length - pos - 1;
        R = referenceArray[(int) [self search : bred : referenceArray : MAX_REF_ARRAY] + (int)(rInterval*pos1) ]; }
    
    double gRange    = (double)abs([self search : agreen : referenceArray : MAX_REF_ARRAY] - [self search : bgreen : referenceArray : MAX_REF_ARRAY]);
    double gInterval = gRange/(double)(length-1);
    if(agreen<=bgreen)
    {
        G = referenceArray[(int)([self search : agreen : referenceArray : MAX_REF_ARRAY] + (int)(gInterval*pos) )];
    }
    
    else
    {   int pos2 = length - pos - 1;
        G = referenceArray[(int)([self search : bgreen : referenceArray : MAX_REF_ARRAY] + (int)(gInterval*pos2) )];}
    
    double bRange    = (double)abs([self search : ablue : referenceArray : MAX_REF_ARRAY] - [self search : bblue : referenceArray : MAX_REF_ARRAY]);
    double bInterval = bRange/(double)(length-1);
    if(ablue <= bblue)
    { B = referenceArray[(int)[self search : ablue : referenceArray : MAX_REF_ARRAY] + (int)(bInterval*pos) ]; }
    
    else
    {   int pos3 = length - pos - 1;
        B = referenceArray[(int)([self search : bblue : referenceArray : MAX_REF_ARRAY] + (int)(bInterval*pos3) )]; }
    
    R = round(R);
    G = round(G);
    B = round(B);
   // NSLog(@" solve2 RGB %f %f %f",R,G,B);

    solvedRGB[R_INDEX] = R*inv255;
    solvedRGB[G_INDEX] = G*inv255;
    solvedRGB[B_INDEX] = B*inv255;

} //end solve

//===HDKGenerator===================================================================
-(NSColor *) solve22 : (NSColor *)a : (NSColor *) b : (int) pos : (int) length
{
    //    public Color solve(Color a, Color b, int pos, int length){
    //double inv255 = 1.0/255.0;
    
    if (!referenceArrayUp)  //Dirty global
    {
        [self initReferenceArray]; //sets up more dirty globals!
        referenceArrayUp = 1;
    }
    
    double R;
    double G;
    double B;
    const CGFloat* acomponents;
    const CGFloat* bcomponents;
    acomponents = CGColorGetComponents(a.CGColor);
    bcomponents = CGColorGetComponents(b.CGColor);
    
    double ared   = 255.0*(double)acomponents[0];
    double agreen = 255.0*(double)acomponents[1];
    double ablue  = 255.0*(double)acomponents[2];
    double bred   = 255.0*(double)bcomponents[0];
    double bgreen = 255.0*(double)bcomponents[1];
    double bblue  = 255.0*(double)bcomponents[2];
    
    double rRange    = (double)abs([self search : ared : referenceArray : MAX_REF_ARRAY] - [self search : bred : referenceArray : MAX_REF_ARRAY] );//diff between reds
    double rInterval = rRange/(double)(length-1);
    
    if( ared <= bred)
    { R = referenceArray[(int) [self search : ared : referenceArray : MAX_REF_ARRAY] + (int)(rInterval*pos) ]; } //DHS does (int)rInterval... round correctly?
    
    else
    {   int pos1 = length - pos - 1;
        R = referenceArray[(int) [self search : bred : referenceArray : MAX_REF_ARRAY] + (int)(rInterval*pos1) ]; }
    
    double gRange    = (double)abs([self search : agreen : referenceArray : MAX_REF_ARRAY] - [self search : bgreen : referenceArray : MAX_REF_ARRAY]);
    double gInterval = gRange/(double)(length-1);
    if(agreen<=bgreen)
    {
        G = referenceArray[(int)([self search : agreen : referenceArray : MAX_REF_ARRAY] + (int)(gInterval*pos) )];
    }
    
    else
    {   int pos2 = length - pos - 1;
        G = referenceArray[(int)([self search : bgreen : referenceArray : MAX_REF_ARRAY] + (int)(gInterval*pos2) )];}
    
    double bRange    = (double)abs([self search : ablue : referenceArray : MAX_REF_ARRAY] - [self search : bblue : referenceArray : MAX_REF_ARRAY]);
    double bInterval = bRange/(double)(length-1);
    if(ablue <= bblue)
    { B = referenceArray[(int)[self search : ablue : referenceArray : MAX_REF_ARRAY] + (int)(bInterval*pos) ]; }
    
    else
    {   int pos3 = length - pos - 1;
        B = referenceArray[(int)([self search : bblue : referenceArray : MAX_REF_ARRAY] + (int)(bInterval*pos3) )]; }
    
    R = round(R);
    G = round(G);
    B = round(B);
    return [NSColor colorWithRed:R*inv255 green:G*inv255 blue:B*inv255 alpha:1.0];
} //end solve



//===HDKGenerator===================================================================
//ZST: here's the methods to get LAB values
//-(NSArray*)getLAB : (NSColor *)a
-(void) getLAB : (NSColor *)a
{
    const CGFloat* acomponents;
    
    acomponents = CGColorGetComponents(a.CGColor);
    double ared   = (double)acomponents[0];
    double agreen = (double)acomponents[1];
    double ablue  = (double)acomponents[2];
    double r = [self xyzc:ared];
    double g = [self xyzc:agreen];
    double b = [self xyzc:ablue];
    
    
    //rgb to xyz
    double xt = r * 0.4124 + g * 0.3576 + b * 0.1805;
    double yt = r * 0.2126 + g * 0.7152 + b * 0.0722;
    double zt = r * 0.0193 + g * 0.1192 + b * 0.9505;
    
    //WhiteReference - off internet
    double whiteX = 95.047;
    double whiteY = 100.000;
    double whiteZ = 108.883;
    
    double x = [self pivotXyz: (xt / whiteX)];
    double y = [self pivotXyz: (yt / whiteY)];
    double z = [self pivotXyz: (zt / whiteZ)];
    
    double L = fmax(0, 116 * y - 16);
    double A = 500 * (x - y);
    double B = 200 * (y - z);
    
    LAB = @[[NSString stringWithFormat: @"%f",L],[NSString stringWithFormat: @"%f",A],[NSString stringWithFormat: @"%f",B]];
    
    //    NSArray *LAB = @[[NSString stringWithFormat: @"%f",L],[NSString stringWithFormat: @"%f",A],[NSString stringWithFormat: @"%f",B]];
    //    return LAB;
} //end getLAB



//===HDKGenerator===================================================================
// Redone w/o objects, straight-C: rgb in are 0..1 range
-(void) getLAB2 : (double) r_in : (double) g_in : (double) b_in
{
    //const CGFloat* acomponents;
    double r = [self xyzc : r_in];
    double g = [self xyzc : g_in];
    double b = [self xyzc : b_in];
    //NSLog(@" getlab2 rgb %f %f %f",r,g,b);
    
    //rgb to xyz
    double xt = r * 0.4124 + g * 0.3576 + b * 0.1805;
    double yt = r * 0.2126 + g * 0.7152 + b * 0.0722;
    double zt = r * 0.0193 + g * 0.1192 + b * 0.9505;
    
    //WhiteReference - off internet
    double whiteX = 95.047;
    double whiteY = 100.000;
    double whiteZ = 108.883;
    
    double x = [self pivotXyz: (xt / whiteX)];
    double y = [self pivotXyz: (yt / whiteY)];
    double z = [self pivotXyz: (zt / whiteZ)];
    
    double L = fmax(0, 116 * y - 16);
    double A = 500 * (x - y);
    double B = 200 * (y - z);

    
    LAB_Array[0] = L;
    LAB_Array[1] = A;
    LAB_Array[2] = B;
    
    
   // LAB = @[[NSString stringWithFormat: @"%f",L],[NSString stringWithFormat: @"%f",A],[NSString stringWithFormat: @"%f",B]];
    //NSLog(@" pack LAB %f %f %f",L,A,B);
//    NSArray *LAB = @[[NSString stringWithFormat: @"%f",L],[NSString stringWithFormat: @"%f",A],[NSString stringWithFormat: @"%f",B]];
//    return LAB;
} //end getLAB



//===HDKGenerator===================================================================
//ZST: here's the methods to get LAB values
//-(NSArray*)getLAB : (NSColor *)a
//  LAB colors are in a wide range from -100? to 100?
-(void) getLAB2 : (NSColor *)a
{
    const CGFloat* acomponents;
    
    acomponents = CGColorGetComponents(a.CGColor);
    double ared   = (double)acomponents[0];
    double agreen = (double)acomponents[1];
    double ablue  = (double)acomponents[2];
    double r = [self xyzc:ared];
    double g = [self xyzc:agreen];
    double b = [self xyzc:ablue];
    
    
    //rgb to xyz
    double xt = r * 0.4124 + g * 0.3576 + b * 0.1805;
    double yt = r * 0.2126 + g * 0.7152 + b * 0.0722;
    double zt = r * 0.0193 + g * 0.1192 + b * 0.9505;
    
    //WhiteReference - off internet
    double whiteX = 95.047;
    double whiteY = 100.000;
    double whiteZ = 108.883;
    
    double x = [self pivotXyz: (xt / whiteX)];
    double y = [self pivotXyz: (yt / whiteY)];
    double z = [self pivotXyz: (zt / whiteZ)];
    
    double L = fmax(0, 116 * y - 16);
    double A = 500 * (x - y);
    double B = 200 * (y - z);
    
    
    LAB_Array[0] = L;
    LAB_Array[1] = A;
    LAB_Array[2] = B;
    
    
    LAB = @[[NSString stringWithFormat: @"%f",L],[NSString stringWithFormat: @"%f",A],[NSString stringWithFormat: @"%f",B]];
    //NSLog(@" pack LAB %f %f %f",L,A,B);
    //    NSArray *LAB = @[[NSString stringWithFormat: @"%f",L],[NSString stringWithFormat: @"%f",A],[NSString stringWithFormat: @"%f",B]];
    //    return LAB;
} //end getLAB


//=====<HDKGenerate>======================================================================
//These next two are just helper methods for getLAB
//formula off internet
-(double )xyzc : (double)ccc {
    
    ccc=((ccc)>0.04045)? pow((((ccc)+0.055)/1.055),2.4)*100 :(ccc)/12.92*100;
    return ccc;
}

//=====<HDKGenerate>======================================================================
//more off internet
-(double)pivotXyz : (double)n {
    return n > 0.008856 ? pow(n,(1.0/3.0)) : (903.3 * n + 16) / 116;
}



//=====<HDKGenerate>======================================================================
-(void) dump
{
    NSLog(@" HDKGenerate dump...(TBD)");
}

//=====<HDKGenerate>======================================================================
-(void) setTLHex : (NSString *) hexstr
{
    int hexint = [self intFromHexString:hexstr];
    int red    = (hexint & 0xff0000) >> 16;
    int green  = (hexint & 0x00ff00) >> 8;
    int blue   = hexint & 0xff;
    _tlColor   = [NSColor colorWithRed:red*INV255 green: green*INV255 blue:blue*INV255 alpha: 1.0f];
    //NSLog(@" TL fromhex %@ :%@",hexstr,_tlColor); //asdf
} //end setTLHex

//=====<HDKGenerate>======================================================================
-(void) setTRHex : (NSString *) hexstr
{
    int hexint = [self intFromHexString:hexstr];
    int red    = (hexint & 0xff0000) >> 16;
    int green  = (hexint & 0x00ff00) >> 8;
    int blue   = hexint & 0xff;
    _trColor   = [NSColor colorWithRed:red*INV255 green: green*INV255 blue:blue*INV255 alpha: 1.0f];
    //NSLog(@" TR fromhex %@ :%@",hexstr,_trColor);
} //end setTRHex

//=====<HDKGenerate>======================================================================
-(void) setBLHex : (NSString *) hexstr
{
    int hexint = [self intFromHexString:hexstr];
    int red    = (hexint & 0xff0000) >> 16;
    int green  = (hexint & 0x00ff00) >> 8;
    int blue   = hexint & 0xff;
    _blColor   = [NSColor colorWithRed:red*INV255 green: green*INV255 blue:blue*INV255 alpha: 1.0f];
    //NSLog(@" BL fromhex %@ :%@",hexstr,_blColor);
} //end setBLHex

//=====<HDKGenerate>======================================================================
-(void) setBRHex : (NSString *) hexstr
{
    int hexint = [self intFromHexString:hexstr];
    int red    = (hexint & 0xff0000) >> 16;
    int green  = (hexint & 0x00ff00) >> 8;
    int blue   = hexint & 0xff;
    _brColor   = [NSColor colorWithRed:red*INV255 green: green*INV255 blue:blue*INV255 alpha: 1.0f];
    //NSLog(@" BR fromhex %@ :%@",hexstr,_brColor);
} //end setBRHex

//=====<HDKGenerate>======================================================================
- (unsigned int)intFromHexString:(NSString *) hexStr
{
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}

//===HDKGenerator===================================================================
- (NSString *) getHexFromColor : (NSColor *) colorin
{
    const CGFloat* components = CGColorGetComponents(colorin.CGColor);
    //NSLog(@"Red: %f", components[0]);
    //NSLog(@"Green: %f", components[1]);
    //NSLog(@"Blue: %f", components[2]);
    NSString *hexout = [NSString stringWithFormat:@"%2.2x%2.2x%2.2x",
                        (int)(255.0*components[0]),
                        (int)(255.0*components[1]),
                        (int)(255.0*components[2])
                        ];
    
    return hexout;
}



//=====<HDKGenerate>======================================================================
//Zach's new tetrahedron math.... (assume colorspace 0..255)
//  assumes tlcolor...brcolor are already loaded
-(double) getColorTetraVolume
{
    [self getColorComponents];
    double ared,agreen,ablue;
    double bred,bgreen,bblue;
    double cred,cgreen,cblue;
    double dred,dgreen,dblue;
    ared   = (double)(1.0 * tlcomponents[0]);
    agreen = (double)(1.0 * tlcomponents[1]);
    ablue  = (double)(1.0 * tlcomponents[2]);
    bred   = (double)(1.0 * trcomponents[0]);
    bgreen = (double)(1.0 * trcomponents[1]);
    bblue  = (double)(1.0 * trcomponents[2]);
    cred   = (double)(1.0 * blcomponents[0]);
    cgreen = (double)(1.0 * blcomponents[1]);
    cblue  = (double)(1.0 * blcomponents[2]);
    dred   = (double)(1.0 * brcomponents[0]);
    dgreen = (double)(1.0 * brcomponents[1]);
    dblue  = (double)(1.0 * brcomponents[2]);
    double ab = sqrt(pow(ared-bred,2)+pow(agreen-bgreen,2)+pow(ablue-bblue,2));
    double ac = sqrt(pow(cred-ared,2)+pow(cgreen-agreen,2)+pow(cblue-ablue,2));
    double ad = sqrt(pow(ared-dred,2)+pow(agreen-dgreen,2)+pow(ablue-dblue,2));
    double bc = sqrt(pow(bred-cred,2)+pow(bgreen-cgreen,2)+pow(bblue-cblue,2));
    double bd = sqrt(pow(bred-dred,2)+pow(bgreen-dgreen,2)+pow(bblue-dblue,2));
    double cd = sqrt(pow(cred-dred,2)+pow(cgreen-dgreen,2)+pow(cblue-dblue,2));

    double a1 = ad*ad;
    double a2 = bd*bd;
    double a3 = cd*cd;
    double a4 = ab*ab;
    double a5 = bc*bc;
    double a6 = ac*ac;

    double volume = sqrt((1.0/144.0)*(a1*a5*(a2+a3+a4+a6-a1-a5)+
                                        a2*a6*(a1+a3+a4+a5-a2-a6)+
                                        a3*a4*(a1+a2+a5+a6-a3-a4)-
                                        a1*a2*a4 - a2*a3*a5 -
                                        a1*a3*a6 - a4*a5*a6));
    volume*=60.0;

    return volume;
} //end getColorTetraVolume


@end