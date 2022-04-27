AWS
===

`[ IN PROGRESS ]`

To deploy this Terraform config to AWS, you'll need the following in addition to
the core requirements listed in the root `README`:

* An AWS account
* Credentials that allow your local machine to create/destroy AWS resources. It
  doesn't matter what kind, since the `backend.tf` config is an empty `s3 {}`
  block.

CHECK OUT `data-backup-storage` FIRST!!!
