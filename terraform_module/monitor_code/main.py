import requests
import smtplib
import os
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
        print(msg)
        return (False, msg)


def run_monitor() -> str:
    send_addr = os.environ["GMAIL_ACCOUNT"]
    dest_addr = os.environ["MONITOR_EMAIL"]
    urls = os.environ["URLS"]

    failing_urls = []
    email_server = login_to_gmail(send_addr)
    for url in urls.split(","):
        ok, email_body = is_site_up(url)
        if not ok:
            msg = EmailMessage()
            msg.set_content(email_body)
            msg["Subject"] = f"{url} is down"
            email_server.send_message(
                msg, from_addr=send_addr, to_addrs=dest_addr
            )
    email_server.quit()

    if failing_urls:
        return f"{len(failing_urls)} URLs returned non-zero responses"
    else:
        return "All URLs passed"


def http_entrypoint(request):
    return run_monitor()
