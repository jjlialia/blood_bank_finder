import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

class EmailService:
    def __init__(self):
        self.smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USER")
        self.smtp_password = os.getenv("SMTP_PASSWORD")

    def _send_email(self, to_email: str, subject: str, body: str):
        if not self.smtp_user or not self.smtp_password:
            print("ERROR: SMTP credentials not set. Email not sent.")
            return False

        try:
            msg = MIMEMultipart()
            msg['From'] = self.smtp_user
            msg['To'] = to_email
            msg['Subject'] = subject

            msg.attach(MIMEText(body, 'plain'))

            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.smtp_user, self.smtp_password)
            text = msg.as_string()
            server.sendmail(self.smtp_user, to_email, text)
            server.quit()
            return True
        except Exception as e:
            print(f"FAILED TO SEND EMAIL: {e}")
            return False

    def send_otp_email(self, email: str, otp: str):
        subject = "Your Blood Bank OTP Code"
        body = f"Hello,\n\nYour one-time password (OTP) for verification is: {otp}\n\nThis code will expire in 10 minutes.\n\nThank you!"
        return self._send_email(email, subject, body)

    def send_notification_email(self, email: str, title: str, message: str):
        subject = f"Blood Bank Update: {title}"
        body = f"Hello,\n\n{message}\n\nBest regards,\nBlood Bank Finder Team"
        return self._send_email(email, subject, body)
