import os
import re

p = os.environ.get("SETTINGS_PATH", "/data/instance/instance/settings.py")
web = os.environ.get("WEB_FQDN", "mail.example.com")
secret = os.environ.get("DJANGO_SECRET_KEY", "CHANGEME_DJANGO_SECRET_KEY")

with open(p, "r", encoding="utf-8") as f:
    s = f.read()

if "DJANGO_SECRET_KEY" not in s and "SECRET_KEY" in s:
    s = re.sub(r"^SECRET_KEY\s*=\s*.*$", f"SECRET_KEY = '{secret}'", s, flags=re.M)

if "ALLOWED_HOSTS" in s:
    s = re.sub(
        r"^ALLOWED_HOSTS\s*=\s*.*$",
        f"ALLOWED_HOSTS = ['{web}','localhost','127.0.0.1']",
        s,
        flags=re.M,
    )
else:
    s += f"\nALLOWED_HOSTS = ['{web}','localhost','127.0.0.1']\n"

if "SECURE_PROXY_SSL_HEADER" not in s:
    s += "\nSECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')\n"

if "USE_X_FORWARDED_HOST" not in s:
    s += "\nUSE_X_FORWARDED_HOST = True\n"

with open(p, "w", encoding="utf-8") as f:
    f.write(s)
