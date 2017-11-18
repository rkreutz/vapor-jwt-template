# vapor-jwt-template
A simple template for an authentication API with JWT using Vapor and MongoDB.

# Preparations
- Make sure your environment variable DATABASE_URL is set and pointing to your Mongo database correctly
- You may add or change the JWT signers inside `jwt.json`

# Generate Signer
You may use the command `gen-signer` to generate a new JWT signer to be added to `jwt.json`. The JSON object will be printed in the console, so you just have to copy it into your config file.

The command also have an argument to set the modulus size in bits for the RSA signer (i.e. `vapor run gen-signer --bits=512`). The default value is `4096`.
