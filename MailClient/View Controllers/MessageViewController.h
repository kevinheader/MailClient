//
//  DetailViewController.h
//  MailClient
//
//  Created by Barney on 8/7/13.
//  Copyright (c) 2013 pvllnspk. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MessageViewController : UIViewController <UISplitViewControllerDelegate>

@property (weak, nonatomic) IBOutlet DTAttributedTextView *bodyTextView;

- (void) setMessage:(CTCoreMessage *)message;

@end