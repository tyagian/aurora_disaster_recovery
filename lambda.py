import time, json, boto3, os, sys, logging, urllib3

COPY_TO_ACCOUNT_TAG = os.environ.get('COPY_TO_ACCOUNT_TAG') 
if not COPY_TO_ACCOUNT_TAG:
 COPY_TO_ACCOUNT_TAG = 'CopyToAccount'

COPY_TO_REGION_TAG = os.environ.get('COPY_TO_REGION_TAG') 
if not COPY_TO_REGION_TAG:
  COPY_TO_REGION_TAG = 'CopyToRegion'

COPY_TO_VAULT_TAG = os.environ.get('COPY_TO_VAULT_TAG') 
if not COPY_TO_VAULT_TAG:
  COPY_TO_VAULT_TAG = 'CopyToVault'

def lambda_handler(event, context):
  # Main lambda function to invoke AWS Backup copy job
  try:
    print(f'Processing Event : {event}')
    detailType = event.get('detail-type')
    if detailType and detailType == 'Copy Job State Change':
        eventDetail = event.get('detail')
        if eventDetail:
          jobState = eventDetail.get('state')
          destinationBackupVaultArn = eventDetail.get('destinationBackupVaultArn')
          iamRoleArn = eventDetail.get('iamRoleArn')
          backupVaultName = destinationBackupVaultArn.split(':')[-1]
          destinationRecoveryPointArn = eventDetail.get('destinationRecoveryPointArn')
          
          if 'COMPLETED' == jobState:
              backup_client = boto3.client('backup')
              response = backup_client.list_tags(ResourceArn=destinationRecoveryPointArn)
              tag_list = response.get('Tags')
              print(f'tag_list from Copy Job :{tag_list}')
              for key in tag_list:
                if key.lower() == COPY_TO_VAULT_TAG.lower():
                  destinationVaultArn = tag_list[key]
                  print(f'Copying {destinationRecoveryPointArn} to {destinationVaultArn} from {backupVaultName}')
                  response = backup_client.start_copy_job(
                    RecoveryPointArn=destinationRecoveryPointArn,
                    SourceBackupVaultName=backupVaultName,
                    DestinationBackupVaultArn=destinationVaultArn,
                    IamRoleArn=iamRoleArn)
                  print(f'start_copy_job done : {response}')
          
  except Exception as e:
    print(e)
