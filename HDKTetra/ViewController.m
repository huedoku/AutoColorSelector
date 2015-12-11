//
//  __     ___                ____            _             _ _
//  \ \   / (_) _____      __/ ___|___  _ __ | |_ _ __ ___ | | | ___ _ __
//   \ \ / /| |/ _ \ \ /\ / / |   / _ \| '_ \| __| '__/ _ \| | |/ _ \ '__|
//    \ V / | |  __/\ V  V /| |__| (_) | | | | |_| | | (_) | | |  __/ |
//     \_/  |_|\___| \_/\_/  \____\___/|_| |_|\__|_|  \___/|_|_|\___|_|
//
//
//  ViewController.m
//  HDKTetra
//
//  Created by Dave Scruton on 11/25/15.
//  Copyright © 2015 Huedoku Labs, Inc. All rights reserved.
//

#import "ViewController.h"
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "HDKCGenerate.h"
#import "CColorSuggester.h"



@implementation ViewController

#define tiffHeaderSize 8

int whichWell;

int whichAlgo;

NSImage *workImage;
NSImage *originalImage;
int workImageWidth,workImageHeight;

NSImage *squareCrosshair;
NSImage *circCrosshair;
int numReducedColors;

IKPictureTaker *pictureTaker;

HDKCGenerate *hdkgen;

CColorSuggester *csugg;

NSButton *cross1;
NSButton *cross2;
NSButton *cross3;
NSButton *cross4;
NSComboBox *cbox;


int crosswh;

NSImageView *imageView;

// These are the UI image params, not the actual image sizes!!!
int imageTop,imageLeft,imageWidth,imageHeight;
int pixelSelectX,pixelSelectY;

//===HDKTetra===================================================================
- (void)viewDidLoad {
    [super viewDidLoad];
    whichWell = 0;
    pictureTaker = [IKPictureTaker pictureTaker];
    csugg = [[CColorSuggester alloc] init];
    crosswh = 40;
    // Do any additional setup after loading the view.
    
    circCrosshair   = [NSImage imageNamed:@"crosscirc128"];
    squareCrosshair = [NSImage imageNamed:@"cross64"];
    _binPopText.stringValue = @"40";
    _colorSimText.stringValue = @"0.15";
    _blockSizeText.stringValue = @"1";
    whichAlgo = ALGO_HISTOGRAM;

} //end viewDidLoad


//===HDKTetra===================================================================
- (void)viewDidAppear {
    [super viewDidAppear];
    [self.view.window setAcceptsMouseMovedEvents:YES];
    
    cross1 = (NSButton *) [[self view] viewWithTag:200];
    cross2 = (NSButton *) [[self view] viewWithTag:201];
    cross3 = (NSButton *) [[self view] viewWithTag:202];
    cross4 = (NSButton *) [[self view] viewWithTag:203];
    cbox   = (NSComboBox *) [[self view] viewWithTag:2000];
    CGRect frame;
    
    //Get image display area from imageview...
    imageView = (NSImageView *) [[self view] viewWithTag:103];
    CGRect fr = imageView.frame;
    imageTop    = fr.origin.y;
    imageLeft   = fr.origin.x;
    imageWidth  = fr.size.width;
    imageHeight = fr.size.height;

    //Place crosshairs at starting points
    int www = 512;
    int hhh = 512;
    
    frame.origin.x    = imageLeft;
    frame.origin.y    = imageTop+imageHeight-crosswh;
    frame.size.width  = crosswh;
    frame.size.height = crosswh;
    
    cross1.frame      = frame;
    frame.origin.x    = imageLeft+www-crosswh;
    cross2.frame      = frame;
    frame.origin.y    = imageTop;
    cross4.frame      = frame;
    frame.origin.x    = imageLeft;
    cross3.frame      = frame;
    
    _tlSwatch.enabled = FALSE;
    _trSwatch.enabled = FALSE;
    _blSwatch.enabled = FALSE;
    _brSwatch.enabled = FALSE;

    [_TopLabel setStringValue:@"Load Image..."];
    
    //    NSLog(@" ivxy %f %f wy %f %f",fr.origin.x,fr.origin.y,fr.size.width,fr.size.height);
    workImage = [NSImage imageNamed:@"testPattern00"];
    originalImage = workImage;
    workImageWidth  = workImage.size.width;
    workImageHeight = workImage.size.height;
    
    csugg.whichAlgo = whichAlgo;
    [csugg load:workImage];
    numReducedColors = [csugg getReducedCount];
    if (numReducedColors < 4)
    {
        [self displayTooFewColorsError : numReducedColors];
    }
    
    [self updateSwatchesAndCrosshairs];
    [self updateLogOutput];

} //end viewdidappear


//===HDKTetra===================================================================
- (void)mouseDown:(NSEvent *)theEvent {
    
}


//===HDKTetra===================================================================
- (void)mouseUp:(NSEvent *)theEvent
{
    
}

//===HDKTetra===================================================================
- (void)mouseDragged:(NSEvent *)theEvent {
    
    NSPoint windowOrigin;
    
    NSWindow *window = self.view.window;
    
    
    windowOrigin = [window frame].origin;
    
    NSPoint np = theEvent.locationInWindow;
    
    int xpos,ypos;
    xpos = np.x;
    ypos = np.y;

    
    //NSLog(@"mm xy %d %d",xpos,ypos);
    xpos-=imageLeft;
    ypos-=imageTop;
    if (xpos >= 0 && ypos>=0 && xpos<=imageWidth && ypos<=imageHeight)
    {
        
        pixelSelectX = xpos;
        pixelSelectY = ypos;
        //NSLog(@" pixelselect %d,%d",pixelSelectX,pixelSelectY);
        [self getColorUnderMouse];
        int invy = workImageHeight-ypos;
        [self updateCrossHair: whichWell : xpos : invy];
        [self updateXYLabel  : whichWell : xpos : invy];

    }
    
} //end mouseDragged


//===HDKTetra===================================================================
-(void)getColorUnderMouse
{
    NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:[workImage TIFFRepresentation]];
   // NSSize imageSize = [workImage size];
   // NSLog(@" size %f,%f",imageSize.width,imageSize.height);
    NSColor* color = [imageRep colorAtX:pixelSelectX y:imageHeight - pixelSelectY];
//    NSLog(@" coloriz %@ %f,%f,%f",color,r,g,b);
    [self updateWell: whichWell :color];

} //end getColorUnderMouse

//===HDKTetra===================================================================
-(void)tweakit
{
    int verbose = 0;
    int x,y,i;
    NSData *data = [originalImage TIFFRepresentation];
    
  //  NSColorSpace *cspace;
    
  //  cspace = [originalImage.
    
    int iwid = originalImage.size.width;
    //OK at this point mb actually has the TIFF raw data.
    //  NOTE first 8 bytes are reserved for TIFF header!
    unsigned char * mb = [data bytes];
    int blen = [data length];
    int rowsize = 3*iwid;
    int numpixels = originalImage.size.width * originalImage.size.height;

    int numchannels = blen / numpixels;

    rowsize = numchannels * iwid;
    
    
    NSLog(@" blen %d iwid %d np %d 3np %d 4np %d numchannels: %d",blen,iwid,numpixels,3*numpixels,4*numpixels,numchannels);
    
    //Copy to 2nd buffer...
    unsigned char *mb2 = (unsigned char *) malloc(blen);
    for (i=0;i<blen;i++) mb2[i] = mb[i];
    
 
    NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:[workImage TIFFRepresentation]];
    //    NSColor* color = [imageRep colorAtX:pixelSelectX y:imageHeight - pixelSelectY];  asdf
    if (verbose)
    {
        x = 10;y = 10;
        for (i=0;i<512;i++)
        {
            int i3 = tiffHeaderSize + numchannels*i;
            
            NSLog(@" data[%d] rgb %x,%x,%x",i,mb[i3],mb[i3+1],mb[i3+2]);
        }
        
    }
    
    
    int mag = _blockSizeText.intValue;
    if (mag <= 0) mag = 1;
    if ((mag > 2) &&  (mag % 2 == 1)) //3 and up and Odd! Ouch!
    {
        mag++;
    }
    if (mag > 32) mag = 32;
    _blockSizeText.stringValue = [NSString stringWithFormat: @"%d",mag];
    NSLog(@" mag is %d",mag);
    int loopx,loopy;
    int iptr;
    for(loopy=0;loopy<workImageHeight;loopy+=mag)
    {
        for(loopx=0;loopx<workImageWidth;loopx+=mag)
        {
         //   -(void) pixelBlock : (unsigned char *) inbuf: (unsigned char *) outbuf : (int) x : (int) y : (int) rowsize : (int) magnification
            [self pixelBlock: mb :mb2 :loopx :loopy : numchannels : rowsize : mag];
        } //end loopx
    } //end loopy
    
    
    //Take our byte array mb, encapsulate it into an NSData object...
    NSData *outData = [[NSData alloc] initWithBytes:mb2 length:blen];
    //Now the NSData object gets turned into an NSImage
    workImage = [[NSImage alloc] initWithData:outData];
    //Replace the image onscreen with our new iamge...
    imageView.image = workImage;

} //end tweakit

//===HDKTetra===================================================================
-(void) pixelBlock : (unsigned char *) inbuf: (unsigned char *) outbuf : (int) x : (int) y : (int) numchannels : (int) rowsize : (int) magnification
{
    unsigned char r,g,b;
    int iptr,optr;
    int loopx,loopy;
    
    iptr = tiffHeaderSize + (numchannels*x) + (rowsize*y);
    r = inbuf[iptr];
    g = inbuf[iptr+1];
    b = inbuf[iptr+2];
    
    for (loopy = 0;loopy < magnification;loopy++)
    {
        optr =  tiffHeaderSize + (numchannels * x) + (rowsize * (y + loopy)); //Starting pointer for our block
        for (loopx = 0;loopx < magnification;loopx++)
        {
            outbuf[optr]   = r;
            outbuf[optr+1] = g;
            outbuf[optr+2] = b;
            optr+=numchannels;
        }
    }
    
    
} //end pixelBlock


//===HDKTetra===================================================================
- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

//===HDKTetra===================================================================
- (IBAction)loadSelect:(id)sender
{
    NSLog(@" load image...");
    [pictureTaker beginPictureTakerWithDelegate:self didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

//===HDKTetra===================================================================
- (void) pictureTakerDidEnd:(IKPictureTaker *) picker

                 returnCode:(NSInteger) code

                contextInfo:(void*) contextInfo

{
    NSImage *image = [picker outputImage];
    NSLog(@" got image... %@",image);
    if (image != nil)
    {
        workImage = [self cropToSquare:image];
        originalImage   = workImage;
        imageView.image = workImage;
        workImageWidth  = workImage.size.width;
        workImageHeight = workImage.size.height;
        [self updateTopLabelWithImageStats];
        [csugg load:workImage];
        numReducedColors = [csugg getReducedCount];
        if (numReducedColors < 4)
        {
            [self displayTooFewColorsError : numReducedColors];
        }
        [self updateSwatchesAndCrosshairs];
        [self updateLogOutput];
    }
    
} //end pictureTakerDidEnd

//===HDKTetra===================================================================
- (IBAction)tetraSelect:(id)sender
{
    NSLog(@"Run AutoSelect algo...");
    int binthresh = _binPopText.intValue;
    if (binthresh == 0)
    {
        binthresh = 40;
        _binPopText.stringValue = @"40";

    }
    float colthresh = _colorSimText.floatValue;
    if (colthresh <= 0)
    {
        colthresh = 0.15;
        _colorSimText.stringValue = @"0.15";
    }

    csugg.binThresh = binthresh;
    csugg.rgbDiffThresh = colthresh;
    
    
    
    [csugg load:workImage];
    numReducedColors = [csugg getReducedCount];
    if (numReducedColors < 4)
    {
        [self displayTooFewColorsError : numReducedColors];
    }
    [self updateSwatchesAndCrosshairs];
    [self updateTopLabelWithImageStats];
    [self updateLogOutput];

} //end tetraSelect


//===HDKTetra===================================================================
- (IBAction)tlSwatchSelect:(id)sender
{
    whichWell = 1;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
    [self selectCrosshair:whichWell];
}


//===HDKTetra===================================================================
- (IBAction)trSwatchSelect:(id)sender
{
    whichWell = 2;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
    [self selectCrosshair:whichWell];
}


//===HDKTetra===================================================================
- (IBAction)blSwatchSelect:(id)sender
{
    whichWell = 3;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
    [self selectCrosshair:whichWell];
}


//===HDKTetra===================================================================
- (IBAction)brSwatchSelect:(id)sender
{
    whichWell = 4;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
    [self selectCrosshair:whichWell];
}

//===HDKTetra===================================================================
- (IBAction)tlSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Top Left..."];
    whichWell = 1;
    [self selectCrosshair:whichWell];
}

//===HDKTetra===================================================================
- (IBAction)trSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Top Right..."];
    whichWell = 2;
    [self selectCrosshair:whichWell];
}

//===HDKTetra===================================================================
- (IBAction)blSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Bottom Left..."];
    whichWell = 3;
    [self selectCrosshair:whichWell];
}


//===HDKTetra===================================================================
- (IBAction)brSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Bottom Right..."];
    whichWell = 4;
    [self selectCrosshair:whichWell];
}

//===HDKTetra===================================================================
- (IBAction)crosshairSelect:(id)sender
{
    NSLog(@" crosshair sender %@",sender);
    if (sender == cross1)
    {
        NSLog(@" cross1...");
    }
    if (sender == cross2)
    {
        NSLog(@" cross2...");
    }
    if (sender == cross3)
    {
        NSLog(@" cross3...");
    }
    if (sender == cross4)
    {
        NSLog(@" cross4...");
    }
//    NSButton whichButton = (NSButton *) [[self view] viewWithTag:1000];
}

//===HDKTetra===================================================================
- (IBAction)testSelect:(id)sender
{
    [self tweakit];
}

//===HDKTetra===================================================================
- (IBAction)algoSelect:(id)sender
{
    NSString *astr = cbox.selectedCell.title;
    if ([astr containsString:@"Histogram"])
    {
        whichAlgo = ALGO_HISTOGRAM;
        _binPopText.enabled = TRUE;
        _colorSimText.enabled = TRUE;
    }
    if ([astr containsString:@"Opposites 1 and 2"])
    {
        whichAlgo = ALGO_OPPOSITE12;
        _binPopText.enabled = FALSE;
        _colorSimText.enabled = FALSE;
    }
    csugg.whichAlgo = whichAlgo;
    NSLog(@" algo select: %@ %d", astr,whichAlgo);

} //end algoSelect




//===HDKTetra===================================================================
// starting hist vals are : ff0000: 22,332 (white?)
-(void) updateXYLabel: (int) which : (int) newx : (int) newy
{
    int invy = workImageHeight - newy; //DO I NEED THIS?
    NSString *lstr = [NSString stringWithFormat:@"%d,%d",newx,newy];
    switch(which)
    {
        case 1:
            [_xylabel00 setStringValue:lstr];
            break;
        case 2:
            [_xylabel01 setStringValue:lstr];
            break;
        case 3:
            [_xylabel02 setStringValue:lstr];
            break;
        case 4:
            [_xylabel03 setStringValue:lstr];
            break;
    }
    
}

//===HDKTetra===================================================================
-(void) updateCrossHair: (int) which : (int) newx : (int) newy
{
    int xpos,ypos;
    
    //NSLog(@" update crosshair %d xy %d %d ww/h %d %d",which,newx,newy,workImageWidth,workImageHeight);
    int invy = workImageHeight - newy;
    xpos = imageLeft  + newx - crosswh*0.5 ;
    ypos = imageTop   + invy - crosswh*0.5 ;
    CGRect frame =  CGRectMake(xpos, ypos, crosswh, crosswh);
    switch(which)
    {
        case 1:
            _crossHair00.frame = frame;
            break;
        case 2:
            _crossHair01.frame = frame;
            break;
        case 3:
            _crossHair02.frame = frame;
            break;
        case 4:
            _crossHair03.frame = frame;
            break;
    }
    
} //end updateCrossHair

//===HDKTetra===================================================================
// Get histogram data and updates swatches...   asdf
-(void) updateSwatchesAndCrosshairs
{
    NSColor *reducedColor1;
    NSColor *reducedColor2;
    NSColor *reducedColor3;
    NSColor *reducedColor4;
    CGPoint rpt1;
    CGPoint rpt2;
    CGPoint rpt3;
    CGPoint rpt4;
    
    
    reducedColor1 = [csugg getNthReducedColor:0];
    reducedColor2 = [csugg getNthReducedColor:1];
    reducedColor3 = [csugg getNthReducedColor:2];
    reducedColor4 = [csugg getNthReducedColor:3];
    
    rpt1 = [csugg getNthReducedXY:0];
    rpt2 = [csugg getNthReducedXY:1];
    rpt3 = [csugg getNthReducedXY:2];
    rpt4 = [csugg getNthReducedXY:3];
    
    //NSLog(@" updateswatches %@ %@ %@ %@",reducedColor1,reducedColor2,reducedColor3,reducedColor4);
    
    [self updateWell : 1 : reducedColor1];
    [self updateWell : 2 : reducedColor2];
    [self updateWell : 3 : reducedColor3];
    [self updateWell : 4 : reducedColor4];
    
    NSLog(@" xy 1234 %f,%f : %f,%f : %f,%f : %f,%f",rpt1.x,rpt1.y,rpt2.x,rpt2.y,rpt3.x,rpt3.y,rpt4.x,rpt4.y);
    
    [self updateCrossHair: 1 : rpt1.x : rpt1.y];
    [self updateCrossHair: 2 : rpt2.x : rpt2.y];
    [self updateCrossHair: 3 : rpt3.x : rpt3.y];
    [self updateCrossHair: 4 : rpt4.x : rpt4.y];
    
    [self updateXYLabel  : 1 : rpt1.x : rpt1.y];
    [self updateXYLabel  : 2 : rpt2.x : rpt2.y];
    [self updateXYLabel  : 3 : rpt3.x : rpt3.y];
    [self updateXYLabel  : 4 : rpt4.x : rpt4.y];

    
} //end updateSwatchesAndCrosshairs


//===HDKTetra===================================================================
-(void) updateTopLabelWithImageStats
{
    NSString *istr = [NSString stringWithFormat:@"Image xy %d,%d size %d",workImageWidth,workImageHeight,workImageWidth*workImageHeight];
    _TopLabel.stringValue = istr;
} //end updateTopLabelWithImageStats


//===HDKTetra===================================================================
-(void) updateWell : (int) which : (NSColor *)color
{
    if (color == nil) return;
    NSColorSpace *cspace;
    cspace = color.colorSpace;
//    NSLog(@" colorspace is %@",cspace);
    
    float r,g,b;
    int cerr = 0;
    @try {
        r = color.redComponent;
        g = color.greenComponent;
        b = color.blueComponent;
        cerr = 0;
    }
    @catch (NSException *exception) {
        NSLog(@" error: bad colorspace %@",cspace);
        cerr = 1;
    }
    if (cerr) return;
    
    //NSLog(@" update well %d color %@",which,color);
    
    NSString *cstr = [self getHexFromColor : color];

    switch (which)
    {
        case 1:
            [_tlSwatch setColor : [NSColor colorWithRed:r green: g blue:b alpha: 1.0f]];
            _tlButton.title = cstr;
            break;
        case 2:
            [_trSwatch setColor : [NSColor colorWithRed:r green: g blue:b alpha: 1.0f]];
            _trButton.title = cstr;
            break;
        case 3:
            [_blSwatch setColor : [NSColor colorWithRed:r green: g blue:b alpha: 1.0f]];
            _blButton.title = cstr;
            break;
        case 4:
            [_brSwatch setColor : [NSColor colorWithRed:r green: g blue:b alpha: 1.0f]];
            _brButton.title = cstr;
            break;
    }

} //end updateWell

//===HDKGenerator===================================================================
- (void)mouseMoved:(NSEvent *)event
{
    //NSLog(@" mm VC");
    //   NSPoint locationInView = [self convertPoint:[event locationInWindow]
    //                                      fromView:nil];
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
} //end getHexFromColor


//===HDKGenerator===================================================================
-(NSImage *) cropToSquare : (NSImage *)input
{
    CGRect frect = CGRectMake(0, 0, 512, 512);
    CGRect srect = CGRectMake(0, 0, input.size.width,input.size.height);
    NSImage *target = [[NSImage alloc]initWithSize:frect.size] ;
    target.backgroundColor = [NSColor greenColor];
    //start drawing on target
    [target lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    
    //draw the portion of the source image on target image
    [input drawInRect:NSMakeRect(0,0,frect.size.width,frect.size.height)
              fromRect:NSMakeRect(0 , 0 , srect.size.width, srect.size.height)
             operation:NSCompositeCopy
              fraction:1.0];
    
    [NSGraphicsContext restoreGraphicsState];
    //end drawing
    [target unlockFocus];
    
    return target;
} //end cropToSquare

//===HDKGenerator===================================================================
// makes selected crosshair yellow: others are white
-(void) selectCrosshair : (int) which
{
    NSLog(@" select Crosshair %d",which);
    switch(which)
    {
        case 1:
            _crossHair00.image = circCrosshair;
            _crossHair01.image = squareCrosshair;
            _crossHair02.image = squareCrosshair;
            _crossHair03.image = squareCrosshair;
            break;
        case 2:
            _crossHair00.image = squareCrosshair;
            _crossHair01.image = circCrosshair;
            _crossHair02.image = squareCrosshair;
            _crossHair03.image = squareCrosshair;
            break;
        case 3:
            _crossHair00.image = squareCrosshair;
            _crossHair01.image = squareCrosshair;
            _crossHair02.image = circCrosshair;
            _crossHair03.image = squareCrosshair;
            break;
        case 4:
            _crossHair00.image = squareCrosshair;
            _crossHair01.image = squareCrosshair;
            _crossHair02.image = squareCrosshair;
            _crossHair03.image = circCrosshair;
            break;
    }
    
} //end selectCrosshair

//===HDKGenerator===================================================================
-(void) displayTooFewColorsError : (int) numcolors
{
    NSString *errmsg = [NSString stringWithFormat:@" Not enough colors found, need 4, only found %d \n Try lowering the Color Similarity Threshold",numcolors];
    [self displayError:errmsg];
} //end displayTooFewColorsError


//===HDKGenerator===================================================================
-(void) displayError : (NSString *) errmsg
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:@"Error..."];
    [alert setInformativeText:errmsg];
     
     [alert beginSheetModalForWindow:self.view.window
                       modalDelegate:self
      
                      didEndSelector:@selector(testDatabaseConnectionDidEnd:returnCode:
                                               contextInfo:)
                         contextInfo:nil];
     }
     
//===HDKGenerator===================================================================
     - (void)testDatabaseConnectionDidEnd:(NSAlert *)alert
                   returnCode:(int)returnCode contextInfo:(void *)contextInfo
    {
      //  NSLog(@"clicked %d button\n", returnCode);
        
    }


//===HDKGenerator===================================================================
-(void) updateLogOutput
{

    int i,rcount,rpop;
    CGPoint rpoint;
    NSColor *rcolor;
    float r,g,b;
    
    rcount = [csugg getReducedCount];
    NSString *dumpit;
    NSString *nextit;
    
    if (whichAlgo == ALGO_HISTOGRAM)
        dumpit = @"Histogram Run...\n";
    else if (whichAlgo == ALGO_OPPOSITE12)
        dumpit = @"Opposites1/2 Run...\n";

    nextit = [NSString stringWithFormat:@"Found %d Colors Overall\n",csugg.binCount];
    dumpit = [dumpit stringByAppendingString:nextit];
    nextit = [NSString stringWithFormat:@"Down to %d Colors After Thresh...\n",csugg.binAfterThreshCount];
    dumpit = [dumpit stringByAppendingString:nextit];

    
    
    nextit = [NSString stringWithFormat:@"Down to %d Reduced Colors after Similarity check...\n",rcount];
    dumpit = [dumpit stringByAppendingString:nextit];
    
    for (i=0;i<rcount;i++)
    {
        rpop   = [csugg getNthReducedPopulation:i];
        rpoint = [csugg getNthReducedXY:i];
        rcolor = [csugg getNthReducedColor:i];
        
        r = rcolor.redComponent;
        g = rcolor.greenComponent;
        b = rcolor.blueComponent;

        nextit = [NSString stringWithFormat:@"[%d] RGB (%3.3d,%3.3d,%3.3d) XY %4.4d,%4.4d  Pop: %d\n",
                  1+i,(int)(255.0*r),(int)(255.0*g),(int)(255.0*b),(int)rpoint.x,(int)rpoint.y,rpop];
        dumpit = [dumpit stringByAppendingString:nextit];
    }
    _logOutput.stringValue = dumpit;
} //end updateLogOutput

@end
