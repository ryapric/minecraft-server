# S3 bucket for world data backups

You'll want to run this from within this folder, with or without using a remote
state but being sure it's a *different* state than the root module one directory
up. Otherwise, you'll run into `destroy` issues since the S3 bucket might not be
empty.
