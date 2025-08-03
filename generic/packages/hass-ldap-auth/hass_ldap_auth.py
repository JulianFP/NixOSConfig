import os

import bonsai

LDAP_ADDRESS = "ldaps://account.partanengroup.de:3636"
LDAP_BIND_USER = "dn=token"
LDAP_BIND_PASSWORD_FILE = "/run/secrets/ldap_token"
BASE_DN = "dc=account,dc=partanengroup,dc=de"
USERNAME_ATTRIBUTES = ["name"]
NAME_ATTRIBUTE = "displayName"
ADMIN_FILTER = "&(class=account)(memberof=spn=hass-admin@account.partanengroup.de)"
USER_FILTER = "&(class=account)(memberof=spn=hass@account.partanengroup.de)"


def main():
    username = os.environ.get("username")
    password = os.environ.get("password")
    if username is None or password is None:
        raise Exception("You need to provide the environment variables 'username' and 'password'!")

    if not os.access(LDAP_BIND_PASSWORD_FILE, os.R_OK):
        raise Exception(f"Could not read file at {LDAP_BIND_PASSWORD_FILE}")

    with open(LDAP_BIND_PASSWORD_FILE, "r") as file:
        bind_password = file.read()

    client = bonsai.LDAPClient(LDAP_ADDRESS)
    client.set_credentials("SIMPLE", user=LDAP_BIND_USER, password=bind_password)
    filter_expression = ""
    for user_attr in USERNAME_ATTRIBUTES:
        filter_expression += f"({user_attr}={username})"

    with client.connect() as conn:
        if admins := conn.search(BASE_DN, 2, f"(&({ADMIN_FILTER})(|{filter_expression}))"):
            if len(admins) > 1:
                raise Exception("Admin query returned more than one user")
            is_admin = True
            user = admins[0]
        elif users := conn.search(BASE_DN, 2, f"(&({USER_FILTER})(|{filter_expression}))"):
            if len(users) > 1:
                raise Exception("User query returned more than one user")
            is_admin = False
            user = users[0]
        else:
            raise Exception(f"Could not find any user with username {username}")

    if not (display_names := user.get(NAME_ATTRIBUTE)) or len(display_names) != 1:
        raise Exception(f"Couldn't get attribute {NAME_ATTRIBUTE} from user {username}")
    if not (user_dn := user.get("dn")):
        raise Exception(f"Couldn't get dn of user {username}")

    client.set_credentials("SIMPLE", user=str(user_dn), password=password)
    with client.connect() as conn:
        if conn.whoami():
            print(f"name = {display_names[0]}")
            if is_admin:
                print("group = system-admin")
            else:
                print("group = system-user")
            print("local_only = false")
            return
        else:
            raise Exception("WhoAmI didn't succeed")
