import sys
import configparser
from pathlib import Path
import smtplib
from email.message import EmailMessage

CONFIG = {}

def get_config(config_path:str, section:str=None) -> dict:
    assert Path(config_path).exists()

    config = configparser.ConfigParser()
    read = config.read(config_path)
    assert read
    
    config_dict = {section: {k: v.strip('"\'') for k, v in config[section].items()} for section in config.sections()}
    return config_dict[section] if section else config_dict


def send_gmail(
        recipient:str, 
        subject:str, 
        body:str, 
        # image_path:str=None, 
        config:dict=CONFIG, 
        # section:str=None
    ):
    message = EmailMessage()
    message['Subject'] = subject
    message.set_content(body)

    # if image_path:
    #     with open(image_path, 'rb') as file:
    #         content = file.read()
    #     message.add_attachment(content, maintype='image', subtype=imghdr.what(None, content))
    # if section:
        # config = config[section]
    
    # print(config)
    HOST = config.get('smtp-server')
    PORT = int(config.get('smtp-port'))
    USER = config.get('user')
    PASSWORD = config.get('password')

    print(f'send_gmail: {HOST     = }')
    print(f'send_gmail: {PORT     = }')
    print(f'send_gmail: {USER     = }')
    print(f'send_gmail: {PASSWORD = }')

    gmail = smtplib.SMTP(HOST, PORT)
    gmail.ehlo()
    gmail.starttls()
    gmail.login(USER, PASSWORD)
    gmail.sendmail(USER, recipient, message.as_string())
    gmail.quit()


if __name__ == '__main__':
    INI_PATH = Path('.secret/.config.ini')
    CONFIG = get_config(INI_PATH, 'mail')

    assert len(sys.argv) == 4

    to, subject, message = sys.argv[1:]
    print(f'send_gmail: {to      = }')
    print(f'send_gmail: {subject = }')
    print(f'send_gmail: {message = }')

    send_gmail(to, subject, message, CONFIG)
