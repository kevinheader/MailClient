//
//  ComposeMessageViewController.m
//  MailClient
//
//  Created by Barney on 8/4/13.
//  Copyright (c) 2013 pvllnspk. All rights reserved.
//

#import "ComposeMessageViewController.h"

@implementation ComposeMessageViewController
{
    NSMutableArray *_toRecipients;
	NSMutableArray *_ccRecipients;
	
    JSTokenField *_fromField;
	JSTokenField *_toField;
	JSTokenField *_ccField;
    UITextField *_subjectField;
    UITextView *_messageBodyView;
    
    UIActivityIndicatorView *_spinner;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initUI];
    [self initData];
    [self initSpinner];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTokenFieldFrameDidChange:)
												 name:JSTokenFieldFrameDidChangeNotification
											   object:nil];
    
    [_fromField addTokenWithTitle:@"iosmailclienttest@gmail.com" representedObject:@"iosmailclienttest@gmail.com"];
}

-(void) initUI
{
    [_topBar setBackgroundColor:BACKGROUND_COLOR];
    
    //From field
    _fromField = [[JSTokenField alloc] initWithFrame:CGRectMake(0, 0, 1040, 35)];
	[[_fromField label] setText:@"From:"];
	[_fromField setDelegate:self];
	[_bodyView addSubview:_fromField];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, _fromField.bounds.size.height-1, _fromField.bounds.size.width, 1)];
    [separator setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [_fromField addSubview:separator];
    [separator setBackgroundColor:[UIColor lightGrayColor]];
	
    //To field
	_toField = [[JSTokenField alloc] initWithFrame:CGRectMake(0, 35, 1040, 35)];
	[[_toField label] setText:@"To:"];
	[_toField setDelegate:self];
	[_bodyView addSubview:_toField];
    
    separator = [[UIView alloc] initWithFrame:CGRectMake(0, _toField.bounds.size.height-1, _toField.bounds.size.width, 1)];
    [separator setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [_toField addSubview:separator];
    [separator setBackgroundColor:[UIColor lightGrayColor]];
	
    //CC field
	_ccField = [[JSTokenField alloc] initWithFrame:CGRectMake(0, 70, 1040, 35)];
	[[_ccField label] setText:@"CC:"];
	[_ccField setDelegate:self];
	[_bodyView addSubview:_ccField];
    
    separator = [[UIView alloc] initWithFrame:CGRectMake(0, _ccField.bounds.size.height-1, _ccField.bounds.size.width, 1)];
    [separator setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [_ccField addSubview:separator];
    [separator setBackgroundColor:[UIColor lightGrayColor]];
    
    //Subject field
    _subjectField = [[UITextField alloc] initWithFrame:CGRectMake(0, 105, 1040, 35)];
    _subjectField.borderStyle = UITextBorderStyleNone;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, 40)];
    label.text = @" Subject:";
    [label setFont:[UIFont fontWithName:@"HelveticaNeue" size:17.0f]];
    [label setTextColor:TEXT_COLOR_PRIMARY];
    _subjectField.leftViewMode = UITextFieldViewModeAlways;
    _subjectField.leftView = label;
    [_subjectField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_bodyView addSubview:_subjectField];
    
    separator = [[UIView alloc] initWithFrame:CGRectMake(0, 140, 1040, 1)];
    [separator setBackgroundColor:[UIColor lightGrayColor]];
    [_bodyView addSubview:separator];
    
    //Message Body field
    _messageBodyView= [[UITextView alloc] initWithFrame:CGRectMake(0, 141, 1040, 1000)];
    [_messageBodyView setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
    _messageBodyView.contentInset = UIEdgeInsetsMake(5,5,5,5);
    [_bodyView addSubview:_messageBodyView];
}

-(void)initData
{
    _toRecipients = [NSMutableArray array];
    _ccRecipients = [NSMutableArray array];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendMessage:(id)sender
{
    
    [self showSpinner];
    
    dispatch_async([AppDelegate serialGlobalBackgroundQueue], ^{
        
        DLog(@"attempt to send an email");
        [TimeExecutionTracker startTrackingWithName:@"sending an email"];
       
        CTCoreMessage *msg = [[CTCoreMessage alloc] init];
        
        NSMutableSet *toRecipients = [NSMutableSet set];
        NSMutableSet *ccRecipients = [NSMutableSet set];
        
        for(NSDictionary *recipient in _toRecipients){
            [toRecipients addObject:[CTCoreAddress addressWithName:[recipient valueForKey:@"email"] email:[recipient valueForKey:@"email"]]];
        }
        
        for(NSDictionary *recipient in _ccRecipients){
            [ccRecipients addObject:[CTCoreAddress addressWithName:[recipient valueForKey:@"email"] email:[recipient valueForKey:@"email"]]];
        }
        
        [msg setTo:toRecipients];
        [msg setCc:ccRecipients];
        [msg setSubject:_subjectField.text];
        [msg setBody:_messageBodyView.text];
        
        NSError *error;
        BOOL success = [CTSMTPConnection sendMessage:msg
                                              server:@"smtp.gmail.com"
                                            username:@"iosmailclienttest@gmail.com"
                                            password:@"testiosmailclienttest"
                                                port:587
                                      connectionType:CTSMTPConnectionTypeStartTLS
                                             useAuth:YES
                                               error:&error];
        
        
        [TimeExecutionTracker stopTrackingAndPrint];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self hideSpinner];
            
            if (success){
                
                DLog(@"Succes...");
                [self cancel:nil];
            }
            else{
                
                DLog(@"Failed...");
            }
            
        });
    });
}


- (void)tokenField:(JSTokenField *)tokenField didAddToken:(NSString *)title representedObject:(id)obj
{
	NSDictionary *recipient = [NSDictionary dictionaryWithObject:title forKey:@"email"];
    
    if(tokenField==_toField){
        
     	[_toRecipients addObject:recipient];
    }else if(tokenField==_ccField){
        
        [_ccRecipients addObject:recipient];
    }
}

- (void)tokenField:(JSTokenField *)tokenField didRemoveToken:(NSString *)title representedObject:(id)obj
{
    NSDictionary *recipient = [NSDictionary dictionaryWithObject:title forKey:@"email"];
    
    if(tokenField==_toField){
        
     	[_toRecipients removeObject:recipient];
    }else if(tokenField==_ccField){
        
        [_ccRecipients removeObject:recipient];
    }
}

- (BOOL)tokenFieldShouldReturn:(JSTokenField *)tokenField
{    
    NSMutableString *recipient = [NSMutableString string];
	
	NSMutableCharacterSet *charSet = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
	[charSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	
    NSString *rawStr = [[tokenField textField] text];
	for (int i = 0; i < [rawStr length]; i++){
		if (![charSet characterIsMember:[rawStr characterAtIndex:i]]){
			[recipient appendFormat:@"%@",[NSString stringWithFormat:@"%c", [rawStr characterAtIndex:i]]];
		}
	}
    
    if ([rawStr length]){
		[tokenField addTokenWithTitle:rawStr representedObject:recipient];
	}
    
    return NO;
}

- (void)handleTokenFieldFrameDidChange:(NSNotification *)note
{
    if ([[note object] isEqual:_toField]){
		[UIView animateWithDuration:0.0
						 animations:^{
							 [_ccField setFrame:CGRectMake(0, [_toField frame].size.height + [_toField frame].origin.y, [_ccField frame].size.width, [_ccField frame].size.height)];
						 }
						 completion:nil];
	}
}


-(void) initSpinner
{
    _spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.center = CGPointMake(self.view.bounds.size.width * 3.0f / 5.0f, 34.0f);
    _spinner.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin
                                 | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    _spinner.hidesWhenStopped = YES;
    [_spinner setColor:[UIColor grayColor]];
    [self.view addSubview:_spinner];
}

-(void) showSpinner
{
    [_spinner startAnimating];
}

-(void) hideSpinner
{
    [_spinner stopAnimating];
}

@end