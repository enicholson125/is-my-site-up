import requests
import smtplib
import os
import random
from email.message import EmailMessage


def login_to_gmail(send_addr: str) -> smtplib.SMTP_SSL:
    gmail_password = os.environ["GMAIL_PASSWORD"]
    server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    server.ehlo()
    server.login(send_addr, gmail_password)
    return server


def is_site_up(url: str) -> (bool, str):
    msg = ""
    r = requests.get(url)
    if r.status_code == 200:
        return (True, msg)
    else:
        msg += f"HTTP status code was {r.status_code}\n"
        msg += f"Output was:\n{r.text}"
        return (False, msg)


def monitor(url: str, send_addr: str, dest_addr: str):
    ok, email_body = is_site_up(url)
    if not ok:
        email_server = login_to_gmail(send_addr)
        msg = EmailMessage()
        msg.set_content(email_body)
        msg["Subject"] = f"{url} is down"
        email_server.send_message(msg, from_addr=send_addr, to_addrs=dest_addr)
        email_server.quit()
    else:
        # Log into GMail every 100 days to keep the
        # email account alive
        if random.randint(0, 100) == 50:
            server = login_to_gmail(send_addr)
            server.quit()

