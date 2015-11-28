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

int whichWell;

NSImage *workImage;

IKPictureTaker *pictureTaker;

HDKCGenerate *hdkgen;

CColorSuggester *csugg;

NSButton *cross1;
NSButton *cross2;
NSButton *cross3;
NSButton *cross4;

int crosswh;

NSImageView *imageView;

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
}


//===HDKTetra===================================================================
- (void)viewDidAppear {
    [super viewDidAppear];
    [self.view.window setAcceptsMouseMovedEvents:YES];
    
    cross1 = (NSButton *) [[self view] viewWithTag:200];
    cross2 = (NSButton *) [[self view] viewWithTag:201];
    cross3 = (NSButton *) [[self view] viewWithTag:202];
    cross4 = (NSButton *) [[self view] viewWithTag:203];
    
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
    [csugg load:workImage];
    // Do any additional setup after loading the view.
}


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

    
    NSLog(@"mm xy %d %d",xpos,ypos);
    xpos-=imageLeft;
    ypos-=imageTop;
    if (xpos >= 0 && ypos>=0 && xpos<=imageWidth && ypos<=imageHeight)
    {
        
        pixelSelectX = xpos;
        pixelSelectY = ypos;
        NSLog(@" pixelselect %d,%d",pixelSelectX,pixelSelectY);
        [self getColorUnderMouse];
        [self updateCrossHair:whichWell :xpos :ypos];
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

   // [imageRep release];
}


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
        imageView.image = workImage;
    }
    
} //end pictureTakerDidEnd

//===HDKTetra===================================================================
- (IBAction)tetraSelect:(id)sender
{
    NSLog(@" run tetra...");
}


//===HDKTetra===================================================================
- (IBAction)tlSwatchSelect:(id)sender
{
    whichWell = 1;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
}


//===HDKTetra===================================================================
- (IBAction)trSwatchSelect:(id)sender
{
    whichWell = 2;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
    
}


//===HDKTetra===================================================================
- (IBAction)blSwatchSelect:(id)sender
{
    whichWell = 3;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
}


//===HDKTetra===================================================================
- (IBAction)brSwatchSelect:(id)sender
{
    whichWell = 4;
    [self updateWell:whichWell :[((NSColorWell *)sender) color]];
}

//===HDKTetra===================================================================
- (IBAction)tlSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Top Left..."];

    whichWell = 1;
}

//===HDKTetra===================================================================
- (IBAction)trSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Top Right..."];
    whichWell = 2;
}

//===HDKTetra===================================================================
- (IBAction)blSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Bottom Left..."];
    whichWell = 3;
}


//===HDKTetra===================================================================
- (IBAction)brSelect:(id)sender
{
    [_TopLabel setStringValue:@"Selected Bottom Right..."];
    whichWell = 4;
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
-(void) updateCrossHair: (int) which : (int) newx : (int) newy
{
    int xpos,ypos;
    xpos = imageLeft  + newx - crosswh*0.5 ;
    ypos = imageTop   + newy - crosswh*0.5 ;
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
-(void) updateWell : (int) which : (NSColor *)color
{
    float r,g,b;
    r = color.redComponent;
    g = color.greenComponent;
    b = color.blueComponent;
    
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

}

- (void)mouseMoved:(NSEvent *)event
{
    NSLog(@" mm VC");
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
}

@end
