//
//  Backend.m
//  BestChat
//
//  Created by HiepHN-imac on 5/26/15.
//  Copyright (c) 2015 Hiep Huynh Ngoc. All rights reserved.
//

#import "Backend.h"

@implementation Backend

+ (NSString *)startPrivateChat:(PFUser *)user1 user2:(PFUser *)user2 {
    NSString *id1 = user1.objectId;
    NSString *id2 = user2.objectId;
    
    NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
    NSArray *members = @[user1.objectId, user2.objectId];
    [self createRecentItem:user1 groupId:groupId member:members description:user2[PF_USER_FULLNAME]];
    [self createRecentItem:user2 groupId:groupId member:members description:user1[PF_USER_FULLNAME]];
    
    return groupId;
}

+ (NSString *)StartMultipleChat:(NSMutableArray *)users {
    NSString *groupId = @"";
    NSString *description = @"";
    
    [users addObject:[PFUser currentUser]];
    
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    
    for (PFUser *user in users) {
        [userIds addObject:user.objectId];
    }
    
    NSArray *sorted = [userIds sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (NSString *userId in sorted) {
        groupId = [groupId stringByAppendingString:userId];
    }
    
    for (PFUser *user in users) {
        if ([description length] != 0) {
            description = [description stringByAppendingString:@" & "];
        }
        description = [description stringByAppendingString:user[PF_USER_FULLNAME]];
    }
    
    for (PFUser *user in users) {
        [self createRecentItem:user groupId:groupId member:userIds description:description];
    }
    return groupId;
}

+ (void)createRecentItem:(PFUser *)user groupId:(NSString *)groupId member:(NSArray *)members description:(NSString *)description {
    PFQuery *query = [PFQuery queryWithClassName:PF_RECENT_CLASS_NAME];
    [query whereKey:PF_RECENT_USER equalTo:user];
    [query whereKey:PF_RECENT_GROUPID equalTo:groupId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if ([objects count] == 0) {
                PFObject *recent = [PFObject objectWithClassName:PF_RECENT_CLASS_NAME];
                recent[PF_RECENT_USER] = user;
                recent[PF_RECENT_GROUPID] = groupId;
                recent[PF_RECENT_MEMBERS] = members;
                recent[PF_RECENT_DESCRIPTION] = description;
                recent[PF_RECENT_LASTUSER] = [PFUser currentUser];
                recent[PF_RECENT_COUNTER] = @0;
                recent[PF_RECENT_UPDATEDACTION] = [NSDate date];
                [recent saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"CreateRecenItem save error.");
                    }
                }];
            }
        }
        else {
            NSLog(@"CreateRecentItem query error.");
        }
    }];
}

+ (void)updateRecentCounter:(NSString *)groupId amount:(NSInteger)amount lastMessage:(NSString *)lastMessage
{
    
    PFQuery *query = [PFQuery queryWithClassName:PF_RECENT_CLASS_NAME];
    [query whereKey:PF_RECENT_GROUPID equalTo:groupId];
    [query includeKey:PF_RECENT_USER];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFObject *recent in objects)
             {
                 if ([recent[PF_RECENT_USER] isEqualTo:[PFUser currentUser]] == NO)
                     [recent incrementKey:PF_RECENT_COUNTER byAmount:[NSNumber numberWithInteger:amount]];
                 recent[PF_RECENT_LASTUSER] = [PFUser currentUser];
                 recent[PF_RECENT_LASTMESSAGE] = lastMessage;
                 recent[PF_RECENT_UPDATEDACTION] = [NSDate date];
                 [recent saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"UpdateRecentCounter save error.");
                  }];
             }
         }
         else NSLog(@"UpdateRecentCounter query error.");
     }];
}

+ (void)clearRecentCounter:(NSString *)groupId{
    PFQuery *query = [PFQuery queryWithClassName:PF_RECENT_CLASS_NAME];
    [query whereKey:PF_RECENT_GROUPID equalTo:groupId];
    [query whereKey:PF_RECENT_USER equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFObject *recent in objects)
             {
                 recent[PF_RECENT_COUNTER] = @0;
                 [recent saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"ClearRecentCounter save error.");
                  }];
             }
         }
         else NSLog(@"ClearRecentCounter query error.");
     }];
}


+ (void)deleteRecentItems:(PFUser *)user1 user2:(PFUser *)user2 {
    PFQuery *query = [PFQuery queryWithClassName:PF_RECENT_CLASS_NAME];
    [query whereKey:PF_RECENT_USER equalTo:user1];
    [query whereKey:PF_RECENT_MEMBERS equalTo:user2.objectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFObject *recent in objects)
             {
                 [recent deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"DeleteMessageItem delete error.");
                  }];
             }
         }
         else NSLog(@"DeleteMessages query error.");
     }];
}
@end
