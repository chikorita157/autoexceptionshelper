//
//  FixSearchDialog.m
//  MAL Updater OS X
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 Atelier Shiori. All rights reserved.
//

#import "FixSearchDialog.h"
#import "EasyNSURLConnection.h"

@interface FixSearchDialog ()

@end

@implementation FixSearchDialog

-(id)init{
    self = [super initWithWindowNibName:@"FixSearchDialog"];
     if(!self)
       return nil;
    return self;
}
- (void)windowDidLoad {
    if (correction) {
        [deleteoncorrection setHidden:NO];
    }
    [super windowDidLoad];
    if ([searchquery length]>0) {
        [search setStringValue:searchquery];
        [self search:nil];
    }
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
}
-(IBAction)closesearch:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:0];
}
-(IBAction)updatesearch:(id)sender {
    NSDictionary * d = [[arraycontroller selectedObjects] objectAtIndex:0];
    if (correction) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:[NSString stringWithFormat:@"Do you want to correct this title as %@?",[d objectForKey:@"title"]]];
        [alert setInformativeText:@"Once done, you cannot undo this action."];
        // Set Message type to Warning
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            goto finish;
        }
    }
    else{
        goto finish;
    }
    finish:
    selectedtitle = [d objectForKey:@"title"];
    selectedaniid = [[d objectForKey:@"id"] stringValue];
    selectedtotalepisodes = [d objectForKey:@"episodes"];
    NSLog(@"%@", selectedaniid);
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:1];
}
-(IBAction)search:(id)sender{
    if ([[search stringValue] length]> 0) {
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
        NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)[search stringValue],
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
        //Set Search API
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://malapi.ateliershiori.moe/anime/search?q=%@", searchterm]];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Perform Search
        [request startRequest];
        // Get Status Code
        int statusCode = [request getStatusCode];
        NSData *response = [request getResponseData];
        dispatch_async(dispatch_get_main_queue(), ^{
        switch (statusCode) {
            case 200:
                [self populateData:response];
                break;
            default:
                break;
        }
        });
        });
    }
    else{
        //Remove all existing Data
        [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    }
}
-(IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Correction-Exception-Help"]];
}
-(void)populateData:(NSData *)data{
    //Remove all existing Data
    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    
    //Parse Data
    NSError* error;
    
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    //Add it to the array controller
    [arraycontroller addObjects:searchdata];
    
    //Show on tableview
    [tb reloadData];
    //Deselect Selection
    [tb deselectAll:self];
}
-(void)setCorrection:(BOOL)correct{
    correction = correct;
}
-(void)setSearchField:(NSString *)term{
    searchquery = term;
}
-(NSString *)getSelectedTitle{
    return selectedtitle;
}
-(NSString *)getSelectedAniID{
    return selectedaniid;
}
-(NSString *)getSelectedTotalEpisodes{
    return selectedtotalepisodes;
}
-(bool)getdeleteTitleonCorrection{
    return [deleteoncorrection state];
}

@end
