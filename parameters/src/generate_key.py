import os
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt
from cryptography.hazmat.backends import default_backend
from base64 import b64encode, b64decode
import uuid

def generate_key_and_save():
    """
    Generates a key using Scrypt and saves it along with its salt to files.
    """
    password_provided = uuid.uuid4().hex  # Generates a random UUID
    salt = os.urandom(16)  # Generate a secure random salt

    kdf = Scrypt(
        salt=salt,
        length=32,
        n=2**14,
        r=8,
        p=1,
        backend=default_backend()
    )
    key = kdf.derive(password_provided.encode())  # Derive a key from the password
    encoded_key = b64encode(key).decode('utf-8')  # Base64 encode the key for easier handling

    # Save the key and salt to files securely, consider encrypting these or using secure storage
    with open("privatekey.key", "w") as key_file:
        key_file.write(encoded_key)
    with open("salt.bin", "wb") as salt_file:
        salt_file.write(salt)

    return encoded_key, salt

if __name__ == "__main__":
    key, salt = generate_key_and_save()
    print("Key:", key)
    print("Salt:", salt.hex())
