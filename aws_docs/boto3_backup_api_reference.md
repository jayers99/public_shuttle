# Boto3 AWS Backup Service API Reference

> Source: [boto3 AWS Backup documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/backup.html)
> Retrieved via Context7 on 2026-04-09

---

## Table of Contents

- [Client Setup](#client-setup)
- [create_backup_plan](#create_backup_plan)
- [create_backup_vault](#create_backup_vault)
- [list_recovery_points_by_backup_vault](#list_recovery_points_by_backup_vault)
- [get_recovery_point_restore_metadata](#get_recovery_point_restore_metadata)
- [Pagination](#pagination)

---

## Client Setup

```python
import boto3

client = boto3.client('backup')
```

---

## create_backup_plan

Creates a backup plan using a backup plan name and backup rules. A backup plan contains information that AWS Backup uses to schedule tasks that create recovery points for resources.

If you call `CreateBackupPlan` with a plan that already exists, you receive an `AlreadyExistsException`.

### Request Syntax

```python
response = client.create_backup_plan(
    BackupPlan={
        'BackupPlanName': 'string',  # Required. 1-50 alphanumeric or '-_.' chars.
        'Rules': [
            {
                'RuleName': 'string',                    # Required. 1-50 alphanumeric or '-_.' chars.
                'TargetBackupVaultName': 'string',       # Required. Logical container for backups.
                'ScheduleExpression': 'string',          # Optional. CRON expression in UTC.
                'StartWindowMinutes': 123,               # Optional. Minutes before job is canceled if not started.
                'CompletionWindowMinutes': 123,          # Optional. Minutes before job is canceled if not completed.
                'Lifecycle': {
                    'MoveToColdStorageAfterDays': 123,   # Optional.
                    'DeleteAfterDays': 123,              # Optional.
                    'OptInToArchiveForSupportedResources': True|False  # Optional.
                },
                'RecoveryPointTags': {'string': 'string'},  # Optional.
                'CopyActions': [
                    {
                        'DestinationBackupVaultArn': 'string',  # Required.
                        'Lifecycle': {
                            'MoveToColdStorageAfterDays': 123,
                            'DeleteAfterDays': 123,
                            'OptInToArchiveForSupportedResources': True|False
                        }
                    },
                ],
                'EnableContinuousBackup': True|False,         # Optional.
                'ScheduleExpressionTimezone': 'string',       # Optional.
                'IndexActions': [
                    {
                        'ResourceTypes': ['string']            # Optional.
                    }
                ]
            },
        ],
        'AdvancedBackupSettings': [
            {
                'ResourceType': 'string',           # e.g. 'EC2'
                'BackupOptions': {'string': 'string'}  # e.g. {'WindowsVSS': 'ENABLED'}
            },
        ]
    },
    BackupPlanTags={'string': 'string'},    # Optional.
    CreatorRequestId='string'                # Optional. Unique identifier for the request.
)
```

### Response

```python
{
    'BackupPlanId': 'string',
    'BackupPlanArn': 'string',
    'CreationDate': datetime(2023, 1, 1),
    'VersionId': 'string',
    'AdvancedBackupSettings': [
        {
            'ResourceType': 'string',
            'BackupOptions': {'string': 'string'}
        }
    ]
}
```

### Example

```python
response = client.create_backup_plan(
    BackupPlan={
        'BackupPlanName': 'my-backup-plan',
        'Rules': [
            {
                'RuleName': 'daily-backup-rule',
                'TargetBackupVaultName': 'my-backup-vault',
                'ScheduleExpression': 'cron(0 12 * * ? *)',
                'StartWindowMinutes': 60,
                'CompletionWindowMinutes': 120,
                'Lifecycle': {
                    'MoveToColdStorageAfterDays': 30,
                    'DeleteAfterDays': 90
                }
            }
        ]
    }
)

print(f"Created backup plan: {response['BackupPlanId']}")
```

---

## create_backup_vault

Creates a logical container where backups are stored (a backup vault).

### Request Syntax

```python
response = client.create_backup_vault(
    BackupVaultName='string',              # Required.
    BackupVaultTags={'string': 'string'},   # Optional.
    EncryptionKeyArn='string',              # Optional. KMS key ARN for encryption.
    CreatorRequestId='string'               # Optional.
)
```

### Example

```python
response = client.create_backup_vault(
    BackupVaultName='my-backup-vault',
    BackupVaultTags={
        'Environment': 'production'
    }
)
```

---

## list_recovery_points_by_backup_vault

Returns a list of recovery points stored in a backup vault.

### Request Syntax

```python
response = client.list_recovery_points_by_backup_vault(
    BackupVaultName='string',              # Required.
    BackupVaultAccountId='string',         # Optional. Filter by account ID.
    ByResourceArn='string',                # Optional. Filter by resource ARN.
    ByResourceType='string',               # Optional. e.g. 'Aurora', 'EC2', 'S3'.
    ByBackupPlanId='string',               # Optional. Filter by backup plan ID.
    ByCreatedBefore=datetime(2023, 1, 1),  # Optional.
    ByCreatedAfter=datetime(2023, 1, 1),   # Optional.
    ByParentRecoveryPointArn='string',     # Optional. For composite backups.
    MaxResults=123,                         # Optional.
    NextToken='string'                      # Optional.
)
```

### Response

```python
{
    'RecoveryPoints': [
        {
            'RecoveryPointArn': 'string',
            'BackupVaultName': 'string',
            'BackupVaultArn': 'string',
            'SourceBackupVaultArn': 'string',
            'ResourceArn': 'string',
            'ResourceType': 'string',
            'CreatedBy': {
                'BackupPlanId': 'string',
                'BackupPlanArn': 'string',
                'BackupPlanVersion': 'string',
                'BackupRuleId': 'string'
            },
            'IamRoleArn': 'string',
            'Status': 'COMPLETED'|'PARTIAL'|'DELETING'|'EXPIRED',
            'StatusMessage': 'string',
            'CreationDate': datetime(2023, 1, 1),
            'InitiationDate': datetime(2023, 1, 1),
            'CompletionDate': datetime(2023, 1, 1),
            'BackupSizeInBytes': 123,
            'CalculatedLifecycle': {
                'MoveToColdStorageAt': datetime(2023, 1, 1),
                'DeleteAt': datetime(2023, 1, 1)
            },
            'Lifecycle': {
                'MoveToColdStorageAfterDays': 123,
                'DeleteAfterDays': 123,
                'OptInToArchiveForSupportedResources': True|False
            },
            'EncryptionKeyArn': 'string',
            'IsEncrypted': True|False,
            'LastRestoreTime': datetime(2023, 1, 1),
            'ParentRecoveryPointArn': 'string',
            'CompositeMemberIdentifier': 'string',
            'IsParent': True|False,
            'ResourceName': 'string',
            'VaultType': 'BACKUP_VAULT'|'LOGICALLY_AIR_GAPPED_BACKUP_VAULT',
            'IndexStatus': 'PENDING'|'ACTIVE'|'FAILED'|'DELETING',
            'IndexStatusMessage': 'string'
        }
    ],
    'NextToken': 'string'
}
```

### Example

```python
response = client.list_recovery_points_by_backup_vault(
    BackupVaultName='my-backup-vault',
    ByResourceType='EC2',
    MaxResults=10
)

for rp in response['RecoveryPoints']:
    print(f"{rp['RecoveryPointArn']} - {rp['Status']} - {rp['CreationDate']}")
```

---

## get_recovery_point_restore_metadata

Retrieves the metadata key-value pairs needed to restore a backup from a recovery point.

### Request Syntax

```python
response = client.get_recovery_point_restore_metadata(
    BackupVaultName='string',         # Required.
    RecoveryPointArn='string',        # Required.
    BackupVaultAccountId='string'     # Optional.
)
```

### Response

```python
{
    'BackupVaultArn': 'string',
    'RecoveryPointArn': 'string',
    'RestoreMetadata': {'string': 'string'},
    'ResourceType': 'string'
}
```

### Example

```python
response = client.get_recovery_point_restore_metadata(
    BackupVaultName='my-backup-vault',
    RecoveryPointArn='arn:aws:backup:us-east-1:123456789012:recovery-point/abcdef12-3456-7890-abcd-ef1234567890'
)

print(f"Resource type: {response['ResourceType']}")
for key, value in response['RestoreMetadata'].items():
    print(f"  {key}: {value}")
```

---

## Pagination

Use the paginator for `list_recovery_points_by_backup_vault` to handle large result sets:

```python
paginator = client.get_paginator('list_recovery_points_by_backup_vault')

page_iterator = paginator.paginate(
    BackupVaultName='my-backup-vault',
    ByResourceType='EC2',
    PaginationConfig={
        'MaxItems': 1000,
        'PageSize': 100
    }
)

for page in page_iterator:
    for rp in page['RecoveryPoints']:
        print(f"{rp['RecoveryPointArn']} - {rp['Status']}")
```
