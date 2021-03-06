//
//  NSString+Additions.h
//  MailClient
//
//  Created by Barney on 7/28/13.
//  Copyright (c) 2013 pvllnspk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (BOOL) contains:(NSString*)substring;
- (BOOL) endsWith:(NSString*)string;
- (NSString *) md5;
- (NSArray*) splitForCharacters:(NSString*)divideCharactes;
- (NSArray*) splitForString:(NSString*)deviderString;

@end
