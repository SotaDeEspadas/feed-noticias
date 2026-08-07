import re
import os
import imaplib
import email
from email.header import decode_header
from datetime import datetime
from typing import List, Dict, Any

TODAY_STR = datetime.now().strftime("%Y-%m-%d")

class GmailNewsletterReader:
    """
    Parser e ingesteador de correos diarios de newsletters financieras
    para la cuenta raul.martinercilla@gmail.com.
    """
    def __init__(self, target_email: str = "raul.martinercilla@gmail.com"):
        self.target_email = target_email
        self.imap_server = os.environ.get("GMAIL_IMAP_SERVER", "imap.gmail.com")
        self.email_user = os.environ.get("GMAIL_USER", target_email)
        self.email_pass = os.environ.get("GMAIL_APP_PASSWORD", "")

    def parse_newsletter_html(self, email_subject: str, html_body: str, sender: str) -> List[Dict[str, Any]]:
        """
        Extrae noticias y enlaces de una newsletter recibida por email.
        """
        extracted_news = []
        source = "Newsletter Email"
        if "fundspeople" in sender.lower() or "funds people" in email_subject.lower():
            source = "Funds People (Email)"
        elif "fundssociety" in sender.lower() or "funds society" in email_subject.lower():
            source = "Funds Society (Email)"
        elif "efpa" in sender.lower() or "efpa" in email_subject.lower():
            source = "EFPA España (Email)"

        links = re.findall(r'href=["\'](https?://[^\s"\']+)["\']', html_body)
        for idx, url in enumerate(links[:5]):
            if any(domain in url for domain in ["fundspeople.com", "fundssociety.com", "efpa.es", "citywire.com"]):
                category = "FONDOS ALTERNATIVOS" if "alterforum" in url.lower() else "Banca Privada"
                extracted_news.append({
                    "id": f"email-news-{idx}-{hash(url) % 10000}",
                    "title": f"Noticia recibida vía Newsletter [{source}]",
                    "url": url,
                    "source": source,
                    "category": category,
                    "date": TODAY_STR,
                    "summary": f"• Extracción automática del boletín diario recibido en {self.target_email}.",
                    "relevance": "Alta" if category == "FONDOS ALTERNATIVOS" else "Media",
                    "entities": [source]
                })
        return extracted_news

    def fetch_today_emails(self) -> List[Dict[str, Any]]:
        """
        Intenta recuperar correos no leídos del día vía IMAP si se han proporcionado credenciales.
        Devuelve noticias extraídas o lista vacía si no hay credenciales activas.
        """
        if not self.email_pass:
            print("[GmailReader] Sin credenciales GMAIL_APP_PASSWORD configuradas. Ingesta desactivada.")
            return []

        news_from_emails = []
        try:
            mail = imaplib.IMAP4_SSL(self.imap_server)
            mail.login(self.email_user, self.email_pass)
            mail.select("inbox")

            date_str = datetime.now().strftime("%d-%b-%Y")
            status, messages = mail.search(None, f'(UNSEEN ON "{date_str}")')

            if status == "OK":
                for msg_id in messages[0].split():
                    res, msg_data = mail.fetch(msg_id, "(RFC822)")
                    for response_part in msg_data:
                        if isinstance(response_part, tuple):
                            msg = email.message_from_bytes(response_part[1])
                            subject, encoding = decode_header(msg["Subject"])[0]
                            if isinstance(subject, bytes):
                                subject = subject.decode(encoding or "utf-8")
                            sender = msg.get("From", "")
                            
                            html_body = ""
                            if msg.is_multipart():
                                for part in msg.walk():
                                    if part.get_content_type() == "text/html":
                                        html_body = part.get_payload(decode=True).decode()
                                        break
                            else:
                                if msg.get_content_type() == "text/html":
                                    html_body = msg.get_payload(decode=True).decode()

                            if html_body:
                                items = self.parse_newsletter_html(subject, html_body, sender)
                                news_from_emails.extend(items)
            mail.logout()
        except Exception as e:
            print(f"[GmailReader] Error al conectar con IMAP Gmail: {e}")
            
        return news_from_emails
