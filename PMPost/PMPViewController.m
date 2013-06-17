//
//  PMPViewController.m
//  PMPost
//
//  Created by Stefano Zanetti on 5/31/13.
//  Copyright (c) 2013 #pragmamark. All rights reserved.
//

#import "PMPViewController.h"
#import "PMPMessageViewController.h"

@interface PMPViewController ()<PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, PMPMessageViewControllerDeleagate>

@end

@implementation PMPViewController

#pragma mark - View life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.parseClassName = @"Post";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 5;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *logOutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logOut:)];
    UIBarButtonItem *meButton = [[UIBarButtonItem alloc] initWithTitle:@"Me" style:UIBarButtonItemStyleBordered target:self action:@selector(me:)];
    self.navigationItem.leftBarButtonItems = @[meButton, logOutButton];
    
    UIBarButtonItem *newMessageButton = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStyleBordered target:self action:@selector(newMessage:)];
    self.navigationItem.rightBarButtonItem = newMessageButton;
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showLoginViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PFLogInViewControllerDelegate

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self loadObjects];
}

#pragma mark - PFSignUpViewControllerDelegate

- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController
           shouldBeginSignUp:(NSDictionary *)info {
    NSString *password = [info objectForKey:@"password"];
    
    
    if(!(password.length >= 8)) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Password has to be at least 8 characters long." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
    
    return (BOOL)(password.length >= 8); // prevent sign up if password has to be at least 8 characters long
};

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    [self loadObjects];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PFQueryTableViewController methods

- (PFQuery *)queryForTable
{
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query includeKey:@"user"];
//    [query includeKey:@"likes"];
    
    [query orderByDescending:@"createdAt"];
    
    return query;
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    static NSString *cellIdentifier = @"Cell";
    
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [object objectForKey:@"title"];
    cell.detailTextLabel.text = [object objectForKey:@"message"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.objects count]) {
        [self loadNextPage];
        return;
    }
    
    PFObject *object = [self.objects objectAtIndex:indexPath.row];
    
    [self showMessageControllerWithObject:object];
    
    NSLog(@"Message: %@", [object objectForKey:@"message"]);
}

#pragma mark - PMPMessageViewControllerDeleagate

- (void)controller:(PMPMessageViewController *)controller didTouchSaveButton:(UIButton *)button
{
    [self loadObjects];
}

#pragma mark - Private methods

- (void)logOut:(id)sender
{
    [PFUser logOut];
    [self showLoginViewControllerAnimated:YES];
}

- (void)me:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"User:" message:[PFUser currentUser].username delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
}

- (void)newMessage:(id)sender
{
    [self showMessageControllerWithObject:nil];
}

- (void)showMessageControllerWithObject:(PFObject *)object
{
    PMPMessageViewController *messageController = [[PMPMessageViewController alloc] initWithNibName:@"PMPMessageViewController" bundle:nil post:object];
    
    messageController.delegate = self;
    
    [self.navigationController pushViewController:messageController animated:YES];
}

- (void)showLoginViewControllerAnimated:(BOOL)animated
{
    if (![PFUser currentUser]) {
        PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
        logInController.delegate = self;
        
        logInController.fields = PFLogInFieldsUsernameAndPassword
        | PFLogInFieldsTwitter
        | PFLogInFieldsFacebook
        | PFLogInFieldsLogInButton
        | PFLogInFieldsSignUpButton;
        
        logInController.signUpController.fields = PFSignUpFieldsUsernameAndPassword
        | PFSignUpFieldsSignUpButton
        | PFSignUpFieldsEmail
        | PFSignUpFieldsDismissButton
        | PFSignUpFieldsAdditional;
        
        logInController.signUpController.signUpView.additionalField.placeholder = @"Nickname";
        
        logInController.logInView.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pragma_mark_logo_1"]];
        logInController.signUpController.signUpView.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pragma_mark_logo_1"]];
        logInController.signUpController.delegate = self;
        
        [self presentViewController:logInController animated:animated completion:nil];
    }
}

@end
