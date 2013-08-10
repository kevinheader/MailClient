//
//  MessagesViewController.m
//  MailClient
//
//  Created by Barney on 8/7/13.
//  Copyright (c) 2013 pvllnspk. All rights reserved.
//

#import "MessagesViewController.h"
#import "NSString+Additions.h"
#import "NSSet+Additions.h"
#import "NSString+Additions.h"
#import "TimeExecutionTracker.h"

@implementation MessagesViewController
{
    CTCoreFolder *_folder;
    
    NSMutableArray *_messages;
    NSMutableArray *_searchResults;
    
    UIActivityIndicatorView *_spinner;
    
    UIRefreshControl *_refreshControl;
    
    NSMutableDictionary *_tableViewCells;
    
    dispatch_queue_t backgroundQueue;
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initViews];
    
    backgroundQueue = dispatch_queue_create("dispatch_queue_#2", 0);
    _tableViewCells = [NSMutableDictionary dictionary];
}


-(void) initViews
{    
    [self initSeacrhBar];
    [self initRefreshControl];
    [self initSpinner];
}

-(void) initSeacrhBar
{
    for (UIView *subview in _searchBarView.subviews){
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            [subview removeFromSuperview];
            break;
        }
    }
    [_searchBarView setBackgroundColor:BACKGROUND_COLOR];
}

-(void) initRefreshControl
{
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl setTintColor:[UIColor colorWithWhite:.75f alpha:1.0]];
    [_refreshControl addTarget:self action:@selector(updateMessages) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:_refreshControl];
}

-(void) initSpinner
{
    _spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.center = CGPointMake(_tableView.bounds.size.width / 2.0f, _tableView.bounds.size.height / 2.0f);
    _spinner.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin
                                 | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    _spinner.hidesWhenStopped = YES;
    [_spinner setColor:[UIColor grayColor]];
    [_tableView addSubview:_spinner];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_searchResults count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *CellIdentifier = @"MessageCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    CTCoreMessage *message = [_searchResults objectAtIndex:indexPath.row];
    
    [(UILabel *)[cell viewWithTag:103] setText:message.subject];
    [(UILabel *)[cell viewWithTag:101] setText:[message.from toStringSeparatingByComma]];
    [(UILabel *)[cell viewWithTag:102] setText:[NSDateFormatter localizedStringFromDate:message.senderDate
                                                                              dateStyle:NSDateFormatterShortStyle
                                                                              timeStyle:NSDateFormatterNoStyle]];
    
    
    if([_tableViewCells valueForKey:[NSString stringWithFormat:@"%d",indexPath.row]] == nil){
        
        if([message.subject isEqualToString:@"Just fot test"]){
            DLog(@" == nil");
        }
        
        [(UILabel *)[cell viewWithTag:104] setText:@"Loading ..."];
        
        dispatch_async(backgroundQueue, ^{
            
            BOOL isHTML;
            NSString *shortBody = [message bodyPreferringPlainText:&isHTML];
            shortBody = [shortBody substringToIndex: MIN(100, [shortBody length])];
            
            if([message.subject isEqualToString:@"Just for test"]){
                DLog(@"  [message bodyPreferringPlainText:&isHTML]");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [_tableViewCells setValue:shortBody forKey:[NSString stringWithFormat:@"%d",indexPath.row]];
                [(UILabel *)[cell viewWithTag:104] setText:[_tableViewCells valueForKey:[NSString stringWithFormat:@"%d",indexPath.row]]];
                [cell setNeedsLayout];
                
                if([message.subject isEqualToString:@"Just fot test"]){
                    DLog(@"   [cell setNeedsLayout];");
                }
                
                
            });
        });
    }else{
        
        if([message.subject isEqualToString:@"Just fot test"]){
            DLog(@" != nil");
        }
        
         [(UILabel *)[cell viewWithTag:104] setText:[_tableViewCells valueForKey:[NSString stringWithFormat:@"%d",indexPath.row]]];
    }
    
    return cell;
}





- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [self setMessage:[_searchResults objectAtIndex:indexPath.row]];
}


-(void)setFolder:(CTCoreFolder *)folder
{
    if (_folder != folder){
        
        _folder = folder;
        
        [self.navigationItem.leftBarButtonItem setTitle:@" / "];
        [self.navigationItem setTitle:folder.path];
        
        [self updateMessages];
    }
}

- (void)updateMessages
{
    if (_folder) {
        
        [self showSpinner];
        
        dispatch_async([AppDelegate serialBackgroundQueue], ^{
            
            DLog(@"Attempt to fetch messages from folder %@ .",[_folder path]);
            
            _messages = [NSMutableArray arrayWithArray:[_folder messagesFromSequenceNumber:1 to:0 withFetchAttributes:CTFetchAttrEnvelope]];
            _searchResults = [_messages mutableCopy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self hideSpinner];
                [_tableView reloadData];
                
                DLog(@"Success. Fetched %d messages.",[_messages count]);
                
            });
        });
        
        if(_refreshControl && [_refreshControl isRefreshing]){
            
            [_refreshControl endRefreshing];
        }
    }
}


-(void) showSpinner
{
    [_messages removeAllObjects];
    [_tableView reloadData];
    
    [_spinner startAnimating];
}

-(void) hideSpinner
{
    [_spinner stopAnimating];
}


-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [_searchResults removeAllObjects];
    
    if(searchText && searchText.length > 0){
        
        for(CTCoreMessage *message in _messages){
            
            if([message.subject contains:searchText]){
                [_searchResults addObject:message];
            }
        }
    }else{
        
        [_searchResults addObjectsFromArray:_messages];
    }
    
    [_tableView reloadData];
}


- (IBAction)returnToMailboxes:(id)sender
{
    DLog(@"returnToMailboxes");
    
    if(_delegate)
        [_delegate closeChildController];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"toComposeMessage"]){
        // segue.destinationViewController;
    }
}

- (IBAction)back:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

@end
