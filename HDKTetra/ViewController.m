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
//  1/28 Add rowskip

#import "ViewController.h"
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "HDKCGenerate.h"
#import "ColorSuggester.h"



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

int smartIndices[4];
int smartCount;

IKPictureTaker *pictureTaker;

HDKCGenerate *hdkgen;

ColorSuggester *csugg;

NSButton *cross1;
NSButton *cross2;
NSButton *cross3;
NSButton *cross4;
NSComboBox *cbox;

int reducedW,reducedH;
unsigned char reducedImage[3*512*512];  //Our shrunk-down picture

int crosswh;

NSImageView *imageView;

// These are the UI image params, not the actual image sizes!!!
int imageTop,imageLeft,imageWidth,imageHeight;
int pixelSelectX,pixelSelectY;

//===HDKTetra===================================================================
- (void)viewDidLoad {
    [super viewDidLoad];
    //NSLog(@" viewDidLoad...");
    whichWell = 0;
    pictureTaker = [IKPictureTaker pictureTaker];
    csugg = [[ColorSuggester alloc] init];
    crosswh = 40;
    // Do any additional setup after loading the view.
    colorDepth = 2;
    blockSize  = 1;
    rowSkip    = 8;
    
    circCrosshair   = [NSImage imageNamed:@"crosscirc128"];
    squareCrosshair = [NSImage imageNamed:@"cross64"];
    _binPopText.stringValue     = @"10";
    _colorSimText.stringValue   = @"0.05";
    _blockSizeText.stringValue  = @"1";
    _colorDepthText.stringValue = @"2";
    _rowSkipText.stringValue    = @"8";
    whichAlgo = ALGO_HISTOGRAM;

} //end viewDidLoad


//===HDKTetra===================================================================
- (void)viewDidAppear {
    //NSLog(@" viewdidappear...");
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
    //int hhh = 512;
    
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
//    workImage = [NSImage imageNamed:@"testPattern00"];
//    workImage = [NSImage imageNamed:@"test2"];
    workImage = [NSImage imageNamed:@"greensun"];
    originalImage = workImage;
    workImageWidth  = workImage.size.width;
    workImageHeight = workImage.size.height;
    
    csugg.whichAlgo = whichAlgo;
    _descriptionLabel.stringValue = [csugg getAlgoDesc];

    binthresh = 1;
    colthresh = 0.15;
    csugg.binThresh = binthresh;
    csugg.rgbDiffThresh = colthresh;

    [self getUIFields];
    processedImage = [csugg preprocessImage : workImage : blockSize : colorDepth];
    imageView.image = processedImage;
    [self runAlgo];

    [self updateUI];

} //end viewdidappear



//===HDKTetra===================================================================
-(void) runAlgo
{
    switch(whichAlgo)
    {
        case ALGO_HISTOGRAM:
            [csugg algo_histogram : processedImage];
            [self smartColors];
            break;
        case ALGO_OPPOSITE12:
            [csugg algo_opposites : processedImage];
            break;
        case ALGO_SHRUNK:
            [csugg algo_shrunk : shrunkImage];
            break;
            
    }

} //end runAlgo

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
        NSLog(@" pixelselect %d,%d",pixelSelectX,pixelSelectY);
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
   NSLog(@" size %d,%d xy %d %d",workImageWidth,workImageHeight,pixelSelectX,pixelSelectY);
    NSColor* color = [imageRep colorAtX:pixelSelectX y:imageHeight - pixelSelectY];
    const CGFloat* components = CGColorGetComponents(color.CGColor);
//asdf
    int r = (int)(components[0] * 255.0);
    int g = (int)(components[1] * 255.0);
    int b = (int)(components[2] * 255.0);
    NSLog(@" coloriz %d,%d,%d",r,g,b);
    [self updateWell: whichWell :color];

} //end getColorUnderMouse

//===HDKTetra===================================================================
-(void) getUIFields
{
    //This is the size in pixels of each of our blocks
    blockSize = _blockSizeText.intValue;
    if (blockSize <= 0) blockSize = 1;
    if ((blockSize > 2) &&  (blockSize % 2 == 1)) //3 and up and Odd! Ouch!
    {
        blockSize++;
    }
    if (blockSize > 32) blockSize = 32;
    _blockSizeText.stringValue = [NSString stringWithFormat: @"%d",blockSize];
    //NSLog(@" blockSize is %d",blockSize);

    
    colorDepth = _colorDepthText.intValue;
    if (colorDepth < 2) colorDepth = 2;
    if (colorDepth > 8) colorDepth = 8;
    _colorDepthText.stringValue = [NSString stringWithFormat: @"%d",colorDepth];

    rowSkip = _rowSkipText.intValue;
    if (rowSkip < 1) rowSkip = 1;
    if (rowSkip > 32) rowSkip = 32;
    _rowSkipText.stringValue = [NSString stringWithFormat: @"%d",rowSkip];

   
} //end getUIFields


//===HDKTetra===================================================================
-(void) lilpixel : (unsigned char *) inbuf : (unsigned char *) outbuf : (int) x : (int) y : (int) numchannels : (int) rowsize : (int) optr
{
    unsigned char r,g,b;
    int iptr,optr3;
    
    iptr = tiffHeaderSize + (numchannels*x) + (rowsize*y);
    r = inbuf[iptr];
    g = inbuf[iptr+1];
    b = inbuf[iptr+2];

    optr3 = optr*3;
    outbuf[optr3]   = r;
    outbuf[optr3+1] = g;
    outbuf[optr3+2] = b;
    
    
    NSLog(@" lilimage xy %d %d RGB %d %d %d",x,y,(int)r,(int)g,(int)b);
} //end lilpixel

//===HDKTetra===================================================================
-(void) pixelBlock : (unsigned char *) inbuf : (unsigned char *) outbuf : (int) x : (int) y : (int) numchannels : (int) rowsize : (int) magnification
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
        [self getUIFields];
        processedImage = [csugg preprocessImage : workImage : blockSize : colorDepth];
        imageView.image = processedImage;
        [self runAlgo];

        [self updateUI];
    }
    
} //end pictureTakerDidEnd

//===HDKTetra===================================================================
- (IBAction)tetraSelect:(id)sender
{
    NSLog(@"Run AutoSelect algo...");
    binthresh = _binPopText.intValue;
    if (binthresh == 0)
    {
        binthresh = 1;
        _binPopText.stringValue = @"10";

    }
    colthresh = _colorSimText.floatValue;
    if (colthresh <= 0)
    {
        colthresh = 0.15;
        _colorSimText.stringValue = @"0.15";
    }

    csugg.binThresh     = binthresh;
    csugg.rgbDiffThresh = colthresh;
    csugg.rowSkip       = rowSkip;
    
    [self getUIFields];
    processedImage = [csugg preprocessImage : workImage : blockSize : colorDepth];

    
    if (whichAlgo == ALGO_SHRUNK)
    {
        NSLog(@" shrunk....");
        NSSize shrinkSize;
        shrinkSize = NSSizeFromCGSize(CGSizeMake(SHRUNKSIZE, SHRUNKSIZE));
        shrunkImage = [self imageResize:processedImage newSize:shrinkSize];
        imageView.image = shrunkImage;
        NSLog(@" shrunk image size %f %f",shrunkImage.size.width,shrunkImage.size.height);
    }
    else
    {
        imageView.image = processedImage;
    }
    [self runAlgo];

    
    [self updateUI];
    
} //end tetraSelect


//===HDKTetra===================================================================
- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
    [sourceImage setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

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
    [self getUIFields];
    NSLog(@" redraw blocksize %d colordepth %d",blockSize,colorDepth);
    processedImage = [csugg preprocessImage : workImage : blockSize : colorDepth];
    imageView.image = processedImage;
    workImage = processedImage;
}

//===HDKTetra===================================================================
- (IBAction)algoSelect:(id)sender
{
    NSString *astr = cbox.selectedCell.title;
    if ([astr containsString:@"Algo 1"])
    {
        whichAlgo = ALGO_HISTOGRAM;
        _binPopText.enabled = TRUE;
        _colorSimText.enabled = TRUE;
    }
    if ([astr containsString:@"Algo 2"])
    {
        whichAlgo = ALGO_OPPOSITE12;
        _binPopText.enabled = TRUE;
        _colorSimText.enabled = TRUE;
    }
    if ([astr containsString:@"Algo 3"])
    {
        whichAlgo = ALGO_SHRUNK;
        _binPopText.enabled = TRUE;
        _colorSimText.enabled = TRUE;
    }
    csugg.whichAlgo = whichAlgo;
    _descriptionLabel.stringValue = [csugg getAlgoDesc];
    NSLog(@" algo select: %@ %d", astr,whichAlgo);
} //end algoSelect


//===HDKTetra===================================================================
-(void) updateUI
{
    numReducedColors = [csugg getReducedCount];
//    if (numReducedColors < 4)
//    {
//        [self displayTooFewColorsError : numReducedColors];
//    }
    [self updateSwatchesAndCrosshairs];
    [self updateTopLabelWithImageStats];
    [self updateLogOutput];
} //end updateUI



//===HDKTetra===================================================================
// starting hist vals are : ff0000: 22,332 (white?)
-(void) updateXYLabel: (int) which : (int) newx : (int) newy
{
    //int invy = workImageHeight - newy; //DO I NEED THIS?
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
    
    //NSLog(@" update crosshair %d xy %d %d",which,newx,newy);
    //NSLog(@"wh w/h %d %d",workImageWidth,workImageHeight);
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
// Let's look at the colors:
//   toss black and white for now...
-(void) smartColors
{
    int i;
    int r,g,b,hhh,lll,sss;
    float rf,gf,bf;
    float rfo,gfo,bfo;
    int hhho;
    float tooCloseToler = 0.05f;
    BOOL tossit;
    const CGFloat* components;
    
    NSColor *testColor;
    for(i=0;i<4;i++) smartIndices[i] = i;
    smartCount = 0;
    int index = 0;
    int rcount = [csugg getReducedCount];
    rfo = gfo = bfo = 0.0;
    hhho = 0;
    for(i=0;i<rcount;i++)
    {
        tossit = FALSE;
        testColor = [csugg getNthReducedColor:i];
        //NSLog(@" tc[%d] %@",i,testColor);
        components= CGColorGetComponents(testColor.CGColor);

        rf = components[0];
        gf = components[1];
        bf = components[2];
        r  = (int)(255.0 * rf);
        g  = (int)(255.0 * gf);
        b  = (int)(255.0 * bf);
        if (rf + gf + bf < 0.03) tossit = TRUE; //Toss black
        if ((fabs(rf - rfo) < tooCloseToler) && (fabs(gf - gfo) < tooCloseToler)) tossit = TRUE; //Toss Too Similar Red/Green
        if ((fabs(rf - rfo) < tooCloseToler) && (fabs(bf - bfo) < tooCloseToler)) tossit = TRUE; //Toss Too Similar Red/Blue
        if ((fabs(gf - gfo) < tooCloseToler) && (fabs(bf - bfo) < tooCloseToler)) tossit = TRUE; //Toss Too Similar Green/Blue

        [csugg RGBtoHLS : r : g : b ];
        hhh = [csugg getHHH];
        lll = [csugg getLLL];
        sss = [csugg getSSS];
        if (abs(hhh - hhho) < 3) tossit = TRUE; //Too similar hue
        
        if (!tossit)
        {
            smartIndices[index] = i;
            NSLog(@" ...found smart index[%d] = %d",index,i);
            NSLog(@"                     RGB    %d %d %d   HLS %d %d %d",r,g,b,hhh,lll,sss);
            index++;
            smartCount++;
        }
        //asdf
        rfo = rf;
        gfo = gf;
        bfo = bf;
        hhho = hhh;
        
    }
    
} //end smartColors

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
    
    reducedColor1 = [csugg getNthReducedColor:smartIndices[0]];
    reducedColor2 = [csugg getNthReducedColor:smartIndices[1]];
    reducedColor3 = [csugg getNthReducedColor:smartIndices[2]];
    reducedColor4 = [csugg getNthReducedColor:smartIndices[3]];
    
    rpt1 = [csugg getNthReducedXY:smartIndices[0]];
    rpt2 = [csugg getNthReducedXY:smartIndices[1]];
    rpt3 = [csugg getNthReducedXY:smartIndices[2]];
    rpt4 = [csugg getNthReducedXY:smartIndices[3]];
    
    //NSLog(@" updateswatches %@ %@ %@ %@",reducedColor1,reducedColor2,reducedColor3,reducedColor4);
    [self updateWell : 1 : reducedColor1];
    [self updateWell : 2 : reducedColor2];
    [self updateWell : 3 : reducedColor3];
    [self updateWell : 4 : reducedColor4];
    

    //NSLog(@" xy 1234 %f,%f : %f,%f : %f,%f : %f,%f",rpt1.x,rpt1.y,rpt2.x,rpt2.y,rpt3.x,rpt3.y,rpt4.x,rpt4.y);
    int xfactor,yfactor;
    xfactor = yfactor = 1;
    if (whichAlgo == ALGO_SHRUNK) xfactor = yfactor = SHRUNKSIZE;
    
    [self updateCrossHair: 1 : xfactor*rpt1.x : yfactor*rpt1.y];
    [self updateCrossHair: 2 : xfactor*rpt2.x : yfactor*rpt2.y];
    [self updateCrossHair: 3 : xfactor*rpt3.x : yfactor*rpt3.y];
    [self updateCrossHair: 4 : xfactor*rpt4.x : yfactor*rpt4.y];
    
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
    else if (whichAlgo == ALGO_HUEHISTOGRAM)
        dumpit = @"Hue Histogram Run...\n";

    nextit = [NSString stringWithFormat:@"Found %d Colors Overall\n",csugg.binCount];
    dumpit = [dumpit stringByAppendingString:nextit];
    nextit = [NSString stringWithFormat:@"Down to %d Colors After Thresh...\n",csugg.binAfterThreshCount];
    dumpit = [dumpit stringByAppendingString:nextit];

    nextit = [NSString stringWithFormat:@"Smart Count %d...\n",smartCount];
    dumpit = [dumpit stringByAppendingString:nextit];

    nextit = [NSString stringWithFormat:@"Down to %d Reduced Colors after Similarity check...\n",rcount];
    dumpit = [dumpit stringByAppendingString:nextit];
    
    for (i=0;i<smartCount;i++)
    {
        int index = smartIndices[i];
        rpop   = [csugg getNthReducedPopulation:index];
        rpoint = [csugg getNthReducedXY:index];
        rcolor = [csugg getNthReducedColor:index];
        
        r = rcolor.redComponent;
        g = rcolor.greenComponent;
        b = rcolor.blueComponent;

        nextit = [NSString stringWithFormat:@"[%d](%d) RGB (%3.3d,%3.3d,%3.3d) XY %4.4d,%4.4d  Pop: %d\n",
                  1+i,index,(int)(255.0*r),(int)(255.0*g),(int)(255.0*b),(int)rpoint.x,(int)rpoint.y,rpop];
        dumpit = [dumpit stringByAppendingString:nextit];
    }
    _logOutput.stringValue = dumpit;
} //end updateLogOutput

@end
