//
//  PMPMessageViewController.m
//  PMPost
//
//  Created by Stefano Zanetti on 5/31/13.
//  Copyright (c) 2013 #pragmamark. All rights reserved.
//

#import "PMPMessageViewController.h"

@interface PMPMessageViewController ()<UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) PFObject *post;
@property (strong, nonatomic) NSArray *comments;

@end

@implementation PMPMessageViewController

#pragma mark - View life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(PFObject *)post
{
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.post = post;
        
        if (self.post) {
            [self loadComments];
        }
    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.userLabel.text = @"";
    self.commentButton.hidden = YES;
    self.pushNotificationSwitch.hidden = YES;
    self.likeButton.selected = NO;
    [self.likeButton setTitle:@"L" forState:UIControlStateNormal];
    
    if (self.post) {
        
        NSString *user = [[self.post objectForKey:@"user"] valueForKey:@"username"];
        
        if (![[[self.post objectForKey:@"user"] objectForKey:@"username"] isEqual:[PFUser currentUser].username]) {
            self.pushNotificationSwitch.hidden = NO;
            self.pushNotificationSwitch.on = [self checkSubcrictionToChannel:user];
        }
        
        self.commentButton.hidden = NO;
        self.titleTextField.text = [self.post valueForKey:@"title"];
        self.messageTextField.text = [self.post valueForKey:@"message"];
        
        self.userLabel.text = [NSString stringWithFormat:@"user: %@", user];
        
        if (![self.post.ACL getWriteAccessForUser:[PFUser currentUser]] )
        {
            self.titleTextField.enabled = NO;
            self.messageTextField.enabled = NO;
            self.saveButton.hidden = YES;
        }
        
        PFRelation *likes = [[PFUser currentUser] objectForKey:@"likes"];
        PFQuery *query = [likes query];
        [query whereKey:@"objectId" equalTo:self.post.objectId];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                // There was an error
            } else {
                if ([objects count] > 0) {
                    self.likeButton.selected = YES;
                    [self.likeButton setTitle:@"U" forState:UIControlStateNormal];
                }
                // objects has all the Posts the current user liked.
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            
            break;
            
        case 1:
            [self addComment:[alertView textFieldAtIndex:0].text];
            break;
        default:
            break;
    }
}

#pragma mark - Private methods

- (void)addComment:(NSString *)textComment
{
    PFObject *comment = [PFObject objectWithClassName:@"Comment"];
    [comment setValue:self.post forKey:@"post"];
    [comment setValue:[PFUser currentUser] forKey:@"user"];
    [comment setValue:textComment forKey:@"text"];
    
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [acl setPublicReadAccess:YES];
    [comment setACL:acl];
    
    [comment saveEventually:^(BOOL succeeded, NSError *error) {
        [self loadComments];
    }];
}

- (void)loadComments
{
    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query whereKey:@"post" equalTo:self.post];
    [query includeKey:@"user"];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.comments = objects;
        [self.tableView reloadData];
    }];
}

- (void)sendNotificationToChannel:(NSString *)channel
{
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:channel];
    [push setMessage:[[NSString stringWithFormat:@"New post from: '%@'", channel] stringByAppendingFormat:@"\n%@", self.titleTextField.text]];
    [push sendPushInBackground];
}

- (BOOL)checkSubcrictionToChannel:(NSString *)channel
{
    return [[PFInstallation currentInstallation].channels containsObject:channel];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CommentCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
    }
    
    PFObject *object = [_comments objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [object objectForKey:@"text"];
    cell.detailTextLabel.text = [[object objectForKey:@"user"] objectForKey:@"username"];
    
    return cell;
}

#pragma mark - IBActions

- (IBAction)saveButtonTouched:(id)sender
{
    if (!self.post) {
        self.post = [PFObject objectWithClassName:@"Post"];
        [self.post setValue:[PFUser currentUser] forKey:@"user"];
        
        PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
        [acl setPublicReadAccess:YES];
        [self.post setACL:acl];
    }
    
    [self.post setValue:self.titleTextField.text forKey:@"title"];
    [self.post setValue:self.messageTextField.text forKey:@"message"];
    
    [self.post saveEventually:^(BOOL succeeded, NSError *error) {
        
        NSString *user = [[self.post objectForKey:@"user"] valueForKey:@"username"];

        [self sendNotificationToChannel:user];
        
        [_delegate controller:self didTouchSaveButton:sender];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (IBAction)commentButtonThouched:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter comment"
                                                    message:@"  "
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (IBAction)valueChanged:(id)sender {
    
    NSString *user = [[self.post objectForKey:@"user"] valueForKey:@"username"];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    if (self.pushNotificationSwitch.on) {
        [currentInstallation addUniqueObject:user forKey:@"channels"];
    }
    else
    {
        [currentInstallation removeObject:user forKey:@"channels"];
    }
    [currentInstallation saveInBackground];
}

- (IBAction)likeButtonTouched:(id)sender {
    
    PFUser *user = [PFUser currentUser];
    PFRelation *likes = [user relationforKey:@"likes"];
    if (self.likeButton.selected) {
        [likes removeObject:self.post];
        [self.likeButton setTitle:@"L" forState:UIControlStateNormal];
    }
    else
    {
        [likes addObject:self.post];
        [self.likeButton setTitle:@"U" forState:UIControlStateNormal];
    }
    
    self.likeButton.selected = !self.likeButton.selected;
    
    [user saveEventually];
}

@end
