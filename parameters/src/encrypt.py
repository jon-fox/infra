from cryptography.fernet import Fernet
import argparse
import os

def load_key():
    """
    Load the previously generated key
    """
    return open("privatekey.key", "rb").read()

def get_filename_without_ext(filename):
    try:
        filename = filename.split(".")[0]
        return filename
    except:
        raise ValueError("Filename must have an extension")

def encrypt(filename, key):
    """
    Given a filename (str) and key (bytes), it encrypts the file and write it
    """
    f = Fernet(key)
    with open(filename, "rb") as file:
        # read all file data
        file_data = file.read()
    filename = get_filename_without_ext(filename)
    encrypted_data = f.encrypt(file_data)
    with open(f"{filename}_encrypted.txt", "wb") as file:
        file.write(encrypted_data)

def decrypt(filename, key):
    """
    Given a filename (str) and key (bytes), it decrypts the file and write it
    """
    f = Fernet(key)
    with open(filename, "rb") as file:
        # read the encrypted data
        encrypted_data = file.read()
    filename = get_filename_without_ext(filename)
    decrypted_data = f.decrypt(encrypted_data)
    with open(f"{filename}_decrypted.txt", "wb") as file:
        file.write(decrypted_data)


def main():
    parser = argparse.ArgumentParser(description="Encrypt or decrypt a file using Fernet symmetric encryption.")
    parser.add_argument("operation", choices=["encrypt", "decrypt"], help="Operation to perform: encrypt or decrypt")
    parser.add_argument("filename", help="The name of the file to encrypt or decrypt")
    parser.add_argument("keyfile", nargs='?', default="privatekey.key", help="The keyfile to use for encryption or decryption")
    args = parser.parse_args()

    if not os.path.exists(args.filename):
        raise FileNotFoundError(f"file '{args.filename}' not found. Please generate the file first.")
    if not os.access(args.filename, os.R_OK):
        raise PermissionError(f"file '{args.filename}' is not readable. Please check the file permissions.")


    key_file = args.keyfile
    if not os.path.exists(key_file):
        raise FileNotFoundError(f"Key file '{key_file}' not found. Please generate the key file first.")

    key = load_key()
    if args.operation == "encrypt":
        encrypt(args.filename, key)
    elif args.operation == "decrypt":
        decrypt(args.filename, key)

# python parameters/src/encrypt.py encrypt parameters/secrets.sh
# python parameters/src/encrypt.py decrypt parameters/secrets_encrypted.txt
if __name__ == "__main__":
    main()
