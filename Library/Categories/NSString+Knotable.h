//
//  NSString+Knotable.h
//  Knotable
//
//  Created by Martin Ceperley on 12/10/13.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Knotable)

- (NSString *) md5;

- (NSString *) trimmed;

- (BOOL)startsWith:(NSString *)string;

- (BOOL) isValidEmail;

- (NSString *)noPrefix:(NSString *)prefix;

@end
