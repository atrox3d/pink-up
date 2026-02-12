import sys
import configparser
from pathlib import Path
import smtplib
from email.message import EmailMessage

# global config object

def get_config(config_path:str, section:str=None) -> dict:
    '''
    parse .ini file and returns dict
    
    :param config_path: path to the .ini file
    :type config_path: str
    :param section: section inside .ini file, if None returns all sections
    :type section: str
    :return: the corresponding dictionary
    :rtype: dict
    '''
    path = Path(__file__).parent / config_path
    assert Path(path).exists(), f"config {path} does not exist"

    config = configparser.ConfigParser()
    read = config.read(path)
    assert read
    
    config_dict = {section: {k: v.strip('"\'') for k, v in config[section].items()} for section in config.sections()}
    return config_dict[section] if section else config_dict


def send_gmail(
        recipient:str, 
        subject:str, 
        body:str,
        config:dict,
        cc_recipient:str=None
    ):
    '''
    sends email through gmail smtp server
    
    :param recipient: recipient(s), comma-separated
    :type recipient: str
    :param subject: subject
    :type subject: str
    :param body: message
    :type body: str
    :param config: config dict containing smtp config
    :type config: dict
    :param cc_recipient: CC recipient(s), comma-separated
    :type cc_recipient: str
    '''
    message = EmailMessage()
    message['Subject'] = subject
    message['To'] = recipient
    if cc_recipient:
        message['Cc'] = cc_recipient
    message.set_content(body)

    # if image_path:
    #     with open(image_path, 'rb') as file:
    #         content = file.read()
    #     message.add_attachment(content, maintype='image', subtype=imghdr.what(None, content))
    
    HOST = config.get('smtp-server')
    PORT = int(config.get('smtp-port'))
    USER = config.get('user')
    PASSWORD = config.get('password')

    # Create a list of all recipients for the SMTP server
    all_recipients = [addr.strip() for addr in recipient.split(',') if addr.strip()]
    if cc_recipient:
        all_recipients.extend([addr.strip() for addr in cc_recipient.split(',') if addr.strip()])

    gmail = smtplib.SMTP(HOST, PORT)
    gmail.ehlo()
    gmail.starttls()
    gmail.login(USER, PASSWORD)
    gmail.sendmail(USER, all_recipients, message.as_string())
    gmail.quit()


if __name__ == '__main__':
    INI_PATH = Path('.secret/.config.ini')
    mail_config = get_config(INI_PATH, 'mail')

    # Updated argument parsing to handle optional CC
    if len(sys.argv) == 4:
        to, subject, message = sys.argv[1:]
        cc = None
    elif len(sys.argv) == 5:
        to, cc, subject, message = sys.argv[1:]
    else:
        print(f'ERROR | syntax: {sys.argv[0]} <to> [<cc>] <subject> <message>')
        sys.exit(1)


    print(f'send_gmail: {to      = }')
    if cc:
        print(f'send_gmail: {cc      = }')
    print(f'send_gmail: {subject = }')
    print(f'send_gmail: {message = }')

    try:
        send_gmail(recipient=to, subject=subject, body=message, config=mail_config, cc_recipient=cc)
    except Exception as e:
        print(f'ERROR | failed to send email: {e}')
        sys.exit(1)
