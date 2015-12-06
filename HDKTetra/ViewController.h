//
//  ViewController.h
//  HDKTetra
//
//  Created by Dave Scruton on 11/25/15.
//  Copyright © 2015 Huedoku Labs, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
- (IBAction)loadSelect:(id)sender;
- (IBAction)tetraSelect:(id)sender;

- (IBAction)tlSwatchSelect:(id)sender;
- (IBAction)trSwatchSelect:(id)sender;
- (IBAction)blSwatchSelect:(id)sender;
- (IBAction)brSwatchSelect:(id)sender;

- (IBAction)tlSelect:(id)sender;
- (IBAction)trSelect:(id)sender;
- (IBAction)blSelect:(id)sender;
- (IBAction)brSelect:(id)sender;
- (IBAction)crosshairSelect:(id)sender;
- (IBAction)testSelect:(id)sender;

@property (weak) IBOutlet NSColorWell *tlSwatch;
@property (weak) IBOutlet NSColorWell *trSwatch;
@property (weak) IBOutlet NSColorWell *blSwatch;
@property (weak) IBOutlet NSColorWell *brSwatch;

@property (weak) IBOutlet NSButton *tlButton;
@property (weak) IBOutlet NSButton *trButton;
@property (weak) IBOutlet NSButton *blButton;
@property (weak) IBOutlet NSButton *brButton;

@property (weak) IBOutlet NSButton *crossHair00;
@property (weak) IBOutlet NSButton *crossHair01;
@property (weak) IBOutlet NSButton *crossHair02;
@property (weak) IBOutlet NSButton *crossHair03;
@property (weak) IBOutlet NSTextField *TopLabel;

@property (weak) IBOutlet NSTextField *xylabel00;
@property (weak) IBOutlet NSTextField *xylabel01;
@property (weak) IBOutlet NSTextField *xylabel02;
@property (weak) IBOutlet NSTextField *xylabel03;
@property (weak) IBOutlet NSTextField *binPopText;
@property (weak) IBOutlet NSTextField *colorSimText;
@property (weak) IBOutlet NSTextField *blockSizeText;

@end

