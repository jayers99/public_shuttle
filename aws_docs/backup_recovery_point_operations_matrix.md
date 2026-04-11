# AWS Backup Recovery Point Operations Matrix

> Which API do you actually call? It depends on the resource type.
>
> Sources: [Feature availability by resource](https://docs.aws.amazon.com/aws-backup/latest/devguide/backup-feature-availability.html), [Supported services](https://docs.aws.amazon.com/aws-backup/latest/devguide/working-with-supported-services.html), [Tags on backups](https://docs.aws.amazon.com/aws-backup/latest/devguide/tags-on-backups.html), [Editing a backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/editing-a-backup.html), [Lifecycle API](https://docs.aws.amazon.com/aws-backup/latest/devguide/API_Lifecycle.html), [Backup plan options](https://docs.aws.amazon.com/aws-backup/latest/devguide/plan-options-and-configuration.html)
>
> Retrieved 2026-04-09

---

## Key Concept: Full AWS Backup Management

This is the root of the confusion. AWS Backup has two modes per resource type:

| Mode | Meaning |
|------|---------|
| **Fully managed** | Recovery points are stored and controlled entirely by AWS Backup. Tags, lifecycle, delete all go through the **Backup API**. Independent encryption supported. |
| **Not fully managed** | Recovery points map to **native service artifacts** (EBS snapshots, RDS snapshots, AMIs). Some operations go through Backup API, others require the **native service API**. |

### Which resource types are fully managed?

| Resource Type | Fully Managed? | Native Artifact |
|---------------|---------------|-----------------|
| **S3** | Yes | None (Backup-native) |
| **EFS** | Yes | None (Backup-native) |
| **RDS** | No | RDS DB Snapshot |
| **Aurora** | No | Aurora DB Cluster Snapshot |
| **EBS** | No (opt-in available) | EBS Snapshot |
| **EC2** | No | AMI + EBS Snapshots |

---

## Operations Matrix

### Legend

| Symbol | Meaning |
|--------|---------|
| `backup` | Use `boto3.client('backup')` |
| `ec2` | Use `boto3.client('ec2')` |
| `rds` | Use `boto3.client('rds')` |
| `s3` | Use `boto3.client('s3')` (not typical for recovery points) |
| YES | Supported |
| NO | Not supported, API will ignore or error |
| -- | Not applicable |

---

### 1. Cold Storage (MoveToColdStorageAfterDays)

| Resource | Supported? | API | Notes |
|----------|-----------|-----|-------|
| **S3** | NO | -- | Backup ignores this setting |
| **EFS** | YES | `backup.update_recovery_point_lifecycle()` | Incremental backups in cold storage |
| **RDS** | NO | -- | Backup ignores this setting |
| **Aurora** | NO | -- | Backup ignores this setting |
| **EBS** | YES | `backup.update_recovery_point_lifecycle()` | Uses EBS Snapshot Archive. Incremental becomes full after transition. Must set `OptInToArchiveForSupportedResources=True` |
| **EC2** | NO | -- | Backup ignores this setting |

**Cold storage constraints:**
- Minimum 90 days in cold storage
- `DeleteAfterDays` must be >= `MoveToColdStorageAfterDays` + 90
- `MoveToColdStorageAfterDays` cannot be changed after transition occurs

---

### 2. Lifecycle Deletion (DeleteAfterDays)

| Resource | Supported? | API | Notes |
|----------|-----------|-----|-------|
| **S3** | YES | `backup.update_recovery_point_lifecycle()` | |
| **EFS** | YES | `backup.update_recovery_point_lifecycle()` | |
| **RDS** | YES | `backup.update_recovery_point_lifecycle()` | |
| **Aurora** | YES | `backup.update_recovery_point_lifecycle()` | |
| **EBS** | YES | `backup.update_recovery_point_lifecycle()` | If EBS Snapshot Lock is applied and lock duration exceeds lifecycle, recovery point status becomes `EXPIRED` instead of being deleted. Must remove snapshot lock first via `ec2.unlock_snapshot()`. |
| **EC2** | YES | `backup.update_recovery_point_lifecycle()` | |

**Note:** Does NOT work on continuous backups (PITR). Use `-1` to remove lifecycle / keep indefinitely.

---

### 3. Delete Recovery Point

| Resource | Supported? | API | Notes |
|----------|-----------|-----|-------|
| **S3** | YES | `backup.delete_recovery_point()` | |
| **EFS** | YES | `backup.delete_recovery_point()` | |
| **RDS** | YES | `backup.delete_recovery_point()` | Do NOT use `rds.delete_db_snapshot()` for Backup-managed snapshots |
| **Aurora** | YES | `backup.delete_recovery_point()` | Do NOT use `rds.delete_db_cluster_snapshot()` for Backup-managed snapshots |
| **EBS** | YES | `backup.delete_recovery_point()` | Do NOT use `ec2.delete_snapshot()` for Backup-managed snapshots. If snapshot has EBS Snapshot Lock, remove lock first. |
| **EC2** | YES | `backup.delete_recovery_point()` | Do NOT use `ec2.deregister_image()` for Backup-managed AMIs |

**All resource types use the Backup API for delete.** AWS explicitly states: "You can't delete a snapshot managed by AWS Backup using the native service. Use AWS Backup."

```python
client = boto3.client('backup')
client.delete_recovery_point(
    BackupVaultName='my-vault',
    RecoveryPointArn='arn:aws:backup:us-east-1:123456789012:recovery-point:abcdef...'
)
```

---

### 4. Tags on Recovery Points

This is where it gets complicated. The API you use depends on whether the resource type is fully managed.

| Resource | Add/Edit Tags | List Tags | Remove Tags | Notes |
|----------|--------------|-----------|-------------|-------|
| **S3** | `backup.tag_resource()` | `backup.list_tags()` | `backup.untag_resource()` | Fully managed - all tag ops through Backup API |
| **EFS** | `backup.tag_resource()` | `backup.list_tags()` | `backup.untag_resource()` | Fully managed - all tag ops through Backup API |
| **RDS** | `rds.add_tags_to_resource()` | `rds.list_tags_for_resource()` | `rds.remove_tags_from_resource()` | Recovery point = RDS snapshot. Use the snapshot ARN. |
| **Aurora** | `rds.add_tags_to_resource()` | `rds.list_tags_for_resource()` | `rds.remove_tags_from_resource()` | Recovery point = Aurora cluster snapshot. Use the snapshot ARN. |
| **EBS** | `ec2.create_tags()` | `ec2.describe_tags()` | `ec2.delete_tags()` | Recovery point = EBS snapshot. Use the snapshot ID. |
| **EC2** | `ec2.create_tags()` | `ec2.describe_tags()` | `ec2.delete_tags()` | Recovery point = AMI. Use the AMI ID. Also tag associated snapshots. |

**Important:** `backup.list_tags()` works on recovery point ARNs for ALL resource types to read Backup-assigned tags. But for non-fully-managed resources, source-copied tags are on the native artifact and must be read/edited through the native API.

**Tag limit:** 50 tags max per recovery point. Backup-assigned tags take priority over source-copied tags.

---

### 5. Tag Copy from Source Resource

| Resource | Auto-copies source tags? | Notes |
|----------|------------------------|-------|
| **S3** | Yes | |
| **EFS** | Yes | |
| **RDS** | Yes | |
| **Aurora** | Yes | |
| **EBS** | Yes | Including nested volumes on EC2 |
| **EC2** | Yes | Tags copied to both AMI and all associated snapshots |

Enable via backup plan: set `CopyTags: true` or configure in backup rule.

For continuous backups: removed source tags are NOT auto-removed from recovery points (must remove manually).

---

## Consolidated Matrix (Quick Reference)

| Operation | S3 | EFS | RDS | Aurora | EBS | EC2 |
|-----------|-----|-----|-----|--------|-----|-----|
| **Fully managed** | Yes | Yes | No | No | Opt-in | No |
| **Cold storage** | No | Yes | No | No | Yes | No |
| **DeleteAfterDays** | Yes | Yes | Yes | Yes | Yes | Yes |
| **Delete recovery point** | `backup` | `backup` | `backup` | `backup` | `backup` | `backup` |
| **Tag: add/edit** | `backup` | `backup` | `rds` | `rds` | `ec2` | `ec2` |
| **Tag: list** | `backup` | `backup` | `rds`* | `rds`* | `ec2`* | `ec2`* |
| **Tag: remove** | `backup` | `backup` | `rds` | `rds` | `ec2` | `ec2` |
| **Lifecycle update** | `backup` | `backup` | `backup` | `backup` | `backup` | `backup` |

\* `backup.list_tags()` returns Backup-assigned tags for all types, but source-copied tags live on the native artifact.

---

## Boto3 Method Signatures

### Backup API (all resource types)

```python
backup = boto3.client('backup')

# Delete recovery point
backup.delete_recovery_point(
    BackupVaultName='string',
    RecoveryPointArn='string'
)

# Update lifecycle (cold storage + deletion)
backup.update_recovery_point_lifecycle(
    BackupVaultName='string',
    RecoveryPointArn='string',
    Lifecycle={
        'MoveToColdStorageAfterDays': 123,    # Only EFS, EBS
        'DeleteAfterDays': 123,                # All types
        'OptInToArchiveForSupportedResources': True  # EBS only
    }
)

# Tags (S3, EFS only - fully managed)
backup.tag_resource(
    ResourceArn='arn:aws:backup:...:recovery-point:...',
    Tags={'Key': 'Value'}
)
backup.untag_resource(
    ResourceArn='arn:aws:backup:...:recovery-point:...',
    TagKeyList=['Key']
)
backup.list_tags(
    ResourceArn='arn:aws:backup:...:recovery-point:...'
)
```

### Native API: RDS / Aurora (tags on snapshots)

```python
rds = boto3.client('rds')

# The ResourceArn is the RDS/Aurora snapshot ARN, not the Backup recovery point ARN
rds.add_tags_to_resource(
    ResourceName='arn:aws:rds:us-east-1:123456789012:snapshot:my-snapshot',
    Tags=[{'Key': 'Environment', 'Value': 'prod'}]
)
rds.remove_tags_from_resource(
    ResourceName='arn:aws:rds:us-east-1:123456789012:snapshot:my-snapshot',
    TagKeys=['Environment']
)
rds.list_tags_for_resource(
    ResourceName='arn:aws:rds:us-east-1:123456789012:snapshot:my-snapshot'
)
```

### Native API: EBS / EC2 (tags on snapshots and AMIs)

```python
ec2 = boto3.client('ec2')

# Use the snapshot ID or AMI ID, not the Backup recovery point ARN
ec2.create_tags(
    Resources=['snap-0123456789abcdef0'],
    Tags=[{'Key': 'Environment', 'Value': 'prod'}]
)
ec2.delete_tags(
    Resources=['snap-0123456789abcdef0'],
    Tags=[{'Key': 'Environment'}]
)
ec2.describe_tags(
    Filters=[{'Name': 'resource-id', 'Values': ['snap-0123456789abcdef0']}]
)
```

---

## How to Get the Native Artifact ID from a Recovery Point

For non-fully-managed resources, you need the native artifact ID to manage tags. Use `describe_recovery_point` and look at the `ResourceArn`:

```python
backup = boto3.client('backup')

response = backup.describe_recovery_point(
    BackupVaultName='my-vault',
    RecoveryPointArn='arn:aws:backup:us-east-1:123456789012:recovery-point:abcdef...'
)

resource_arn = response['ResourceArn']
# For EBS: 'arn:aws:ec2:us-east-1:123456789012:volume/vol-...'
# For EC2: 'arn:aws:ec2:us-east-1:123456789012:instance/i-...'
# For RDS: 'arn:aws:rds:us-east-1:123456789012:db:my-database'
# For Aurora: 'arn:aws:rds:us-east-1:123456789012:cluster:my-cluster'

# The recovery point ARN itself encodes the snapshot/AMI for non-fully-managed types:
# EBS recovery point -> maps to an EBS snapshot
# EC2 recovery point -> maps to an AMI (with associated snapshots)
# RDS recovery point -> maps to an RDS snapshot
# Aurora recovery point -> maps to an Aurora cluster snapshot
```
