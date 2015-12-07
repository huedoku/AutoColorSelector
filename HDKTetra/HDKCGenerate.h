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
//  Created by Dave Scruton on 8/1/15.
//  Copyright (c) 2015 huedoku, inc. All rights reserved.
//
//  NOTE!!! all properties with pointers MUST BE CAST strong!
//             otherwise the code runs but krashes!
//          This version is similar to but different from the iOS
//            version, be careful cross-integrating!

#import <Foundation/Foundation.h>
//We need this for iOS apps (Switch NSColor to UIColor)
//#import <UIKit/UIKit.h>
//We need this for Cocoa apps,
#import <Cocoa/Cocoa.h>

#define BIGGEST_PUZZLE 21
#define MAX_HDKGEN_COLORS 21*21
#define MAX_REF_ARRAY 256

@interface HDKCGenerate : NSObject
{
    NSColor  *colorz[MAX_HDKGEN_COLORS];  //overdimensioned!
    int referenceArrayUp;
    double referenceArray[MAX_REF_ARRAY];
    int rgbarray[BIGGEST_PUZZLE][BIGGEST_PUZZLE][3];
   // NSColor* c[BIGGEST_PUZZLE][BIGGEST_PUZZLE];
    const CGFloat* tlcomponents;
    const CGFloat* trcomponents;
    const CGFloat* blcomponents;
    const CGFloat* brcomponents;
    const CGFloat* rgbcomponents;
    double inv255;
    NSArray *LABtlcorner;
    NSArray *LABtrcorner;
    NSArray *LABblcorner;
    NSArray *LABbrcorner;
    
    NSArray *LAB;

    double LAB_Array[4];
    double LABtl_Array[4];
    double LABtr_Array[4];
    double LABbl_Array[4];
    double LABbr_Array[4];
    
    double solvedRGB[4];
    
    double finalColorz[MAX_HDKGEN_COLORS][3]; //up to 7x7 array here...
}

@property (nonatomic , assign) int       xsize;
@property (nonatomic , assign) int       ysize;
@property (nonatomic , assign) int       difficulty;
@property (nonatomic , strong) NSColor*  tlColor;
@property (nonatomic , strong) NSColor*  trColor;
@property (nonatomic , strong) NSColor*  blColor;
@property (nonatomic , strong) NSColor*  brColor;
@property (nonatomic , assign) double    HCval;
@property (nonatomic , assign) double    LPval;
@property (nonatomic , assign) double    RGval;
@property (nonatomic , assign) double    YBval;


-(void) setColor : (int) which : (NSColor *) color;
-(NSColor *) getColor: (int) which;
-(void) generateZachArray;
-(void) generateZachArray2;
-(void) setTLHex : (NSString *) hexstr;
-(void) setTRHex : (NSString *) hexstr;
-(void) setBLHex : (NSString *) hexstr;
-(void) setBRHex : (NSString *) hexstr;
-(double) getColorTetraVolume;

-(void) dump;


@end