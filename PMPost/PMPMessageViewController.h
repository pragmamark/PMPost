//
//  PMPMessageViewController.h
//  PMPost
//
//  Created by Stefano Zanetti on 5/31/13.
//  Copyright (c) 2013 #pragmamark. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PMPMessageViewController;

@protocol PMPMessageViewControllerDeleagate <NSObject>

- (void)controller:(PMPMessageViewController *)controller didTouchSaveButton:(UIButton *)button;

@end

@interface PMPMessageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISwitch *pushNotificationSwitch;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;

@property (weak, nonatomic) id<PMPMessageViewControllerDeleagate>delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(PFObject *)post;

- (IBAction)saveButtonTouched:(id)sender;
- (IBAction)commentButtonThouched:(id)sender;
- (IBAction)valueChanged:(id)sender;
- (IBAction)likeButtonTouched:(id)sender;


@end
