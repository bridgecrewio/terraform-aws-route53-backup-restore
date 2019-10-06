import boto3

route53 = boto3.client('route53')


def get_route53_zone_records(zone_id, start_record_name=None, start_record_type=None):
    if start_record_name and start_record_type:
        response = route53.list_resource_record_sets(HostedZoneId=zone_id, StartRecordName=start_record_name, StartRecordType=start_record_type)
    else:
        response = route53.list_resource_record_sets(HostedZoneId=zone_id)
    zone_records = response['ResourceRecordSets']

    if response['IsTruncated']:
        zone_records += get_route53_zone_records(zone_id, response['NextRecordName'], response['NextRecordType'])

    return zone_records


def get_route53_health_checks(marker=None):
    if marker:
        response = route53.list_health_checks(Marker=marker)
    else:
        response = route53.list_health_checks()
    health_checks = response['HealthChecks']
    if response['IsTruncated']:
        health_checks += get_route53_health_checks(response['NextMarker'])

    return health_checks
