# is-my-site-up

This will connect to a website and email you if the website does not return 200.
It is packaged into a Google Cloud Function that by default runs every day.

## Setup

### Requirements

 - A Gmail account to send the email. I *strongly* recommend that you create a
   dedicated account for this, as configuring a Gmail account to be accessible to this script
   involves disabling security features, such as turning on less secure apps access.
 - Google Cloud Platform account
 - Terraform

### Configure the Gmail account

 - (Create a Gmail account)[]
 - Go to the (less secure apps section of settings)[https://myaccount.google.com/lesssecureapps] 
 - Turn allow less secure access on
 - (Optional) Change the account (inactivity settings)[https://myaccount.google.com/inactive] to the maximum of
   18 months and configure the inactivity warnings, so if your site is very stable, your monitoring won't silently disappear

### Run the Terraform

