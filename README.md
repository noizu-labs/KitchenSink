# KitchenSink
The repo contains various Bells and Whistles used by various Internal and Public Noizu projects. 

## Smart Token
Smart Tokens provide a mechanism to associate a query token with a given set of permissions and access attempts. 
It may be used, for example, for a single login link, or to allow 5 downloads of a specific file. 

- Time Limited Tokens
- Use Limited Tokens
- Permission Grant 
- Context (limit permission grant to specific entities)
- Tamper Protection 

## Email Service: Transaction Email, Template Email, Email Queue  

### Transactional Emails 
Transaction emails allows for defining emails that should be sent under specific conditions along with 
the default binding and tokens that should be generated on creation. 

### Template Emails 
System for synchronizing email templates with SendGrid (or other source) and binding for delivery. 
Current version heavy targeted towards SendGrid's built in Template support but will be extended in the future 
for CMS backed templates and dynamic email generation from template for email services that do not support template binding. 

### CMS
 Basic system to tracking versioned articles/files/images. [WIP]

## Pending 
updates need to be pulled in from various repos for these

### Feature Versioning
Support for controlling which versions of site features a user has access to. Basically an Access Control List and some related APIs
for fetching what modules a user should be allowed to access from a website. Used to control what components are displayed in front-end system, 
not as a backend security solution.

- Roll out beta and alpha versions of features to a subset of users. 
- Let users pick their preferred module. Do you have seeing impaired users they might 
want a different layout than a sighted user. Do you have a super user they might want 
access to different components than regular users. etc.    

### Credentials 
- Basic tracking of user credentials from multiple sources. (Facebook, Oauth, Google, etc. tied to single underlying account)

### User Settings 
- Tree setting structure that incorporates weight and inheritance.  

  Use fills in setting with specified paths `path = [Top, Parent, ParentsParent]` and weight. To calculate 
  the effective setting for a given path the system grabs all entries at 
  `path = [Top, Parent, ParentsParent]`, `path = [Parent, ParentsParent]`, `path = [ParentsParent]`, and `path = []`.
  The entry with the highest weight at the given path (and it's parents) is returned as the effective value.
  This allows the library user to build up a tree of default settings and allow the user to override these at a specific level of globally.
  
  You could for example specify log levels to initiate different systems with. `path = [:email_system, :communmication, :monitoring]` 
  and allow the end user to override any value within  monitoring, or a subset (if you use a much higher weight for critical systems). or another leaf on the tree.
  
  You may also lookup the effective setting of multiple paths `effective_for(settings, setting, [path_1, path_2])`
   
  @note this library is not highly optomized and is innapropriate for scenarios where it will be called frequently against large settings structs. 

### EAV 
- Basic Entity Attribute Value support. 