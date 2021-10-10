# is-my-site-up

This pings a URL and emails you if it doesn't return 200.
It is packaged into a Google Cloud Function that by default runs every day.

## Setup

### Requirements

 - A Gmail account to send the email. I *strongly* recommend that you create a
   dedicated account for this, as configuring a Gmail account to be accessible to this script
   involves disabling security features, such as turning on less secure apps access.
 - Google Cloud Platform account
 - Terraform

### Configure the Gmail account

 - [Create a Gmail account](https://accounts.google.com/signup/v2/webcreateaccount)
 - Go to the [less secure apps section of settings](https://myaccount.google.com/lesssecureapps)
 - Turn allow less secure access on
 - (Optional) Change the account [inactivity settings](https://myaccount.google.com/inactive) to the maximum of
   18 months and configure the inactivity warnings, so if your site is very stable, your monitoring won't silently disappear

### Run the Terraform

 - You will need the Cloud Functions, Cloud Scheduler and Cloud Build APIs enabled to run the terraform. Terraform prompts you to enable them so personally I keep applying and clicking through on the enable links until it works
 - You will need to create an App Engine instance

Invoke the module in your terraform, e.g.

```
module "cheatsheet" {
  source = "./terraform"

  gmail_account  = "gmail-account-you-created-earlier@gmail.com"
  urls_to_check  = "https://terraform-cheatsheet.uk"
  email_to_alert = "gmail-account-to-email-if-down@gmail.com"
}
```

Run `terraform plan` and `terraform apply` to create the Cloud Function.

You will then need to manually create the Gmail password secret in Cloud Secrets and add it to the Cloud function by following [this documentation](https://cloud.google.com/functions/docs/configuring/secrets#making_a_secret_accessible_to_a_function) (add it as an environment variable called `GMAIL_PASSWORD`). It's not currently possible to set that in the terraform and it doesn't persist across recreating the terraform version of the cloud function, which is a shame.

