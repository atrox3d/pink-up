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
        config:dict, 
        # section:str=None
    ):
    '''
    sends email through gmail smtp server
    
    :param recipient: recipient
    :type recipient: str
    :param subject: subject
    :type subject: str
    :param body: message
    :type body: str
    :param config: config dict containing smtp config
    :type config: dict
    '''
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
    mail_config = get_config(INI_PATH, 'mail')

    try:
        assert len(sys.argv) == 4
    except:
        print(f'ERROR | syntax: {sys.argv[0]} <to> <subject> <message>')
        sys.exit(1)


    to, subject, message = sys.argv[1:]
    print(f'send_gmail: {to      = }')
    print(f'send_gmail: {subject = }')
    print(f'send_gmail: {message = }')

    try:
        send_gmail(to, subject, message, mail_config)
    except:
        print('ERROR | failed to send email')
        sys.exit(1)
