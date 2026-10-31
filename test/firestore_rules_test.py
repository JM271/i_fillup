"""Run against the local Firestore emulator on port 8787 (demo-i-fillup only)."""
import base64
import json
import time
import urllib.error
import urllib.request
import uuid

BASE = 'http://127.0.0.1:8787/v1/projects/demo-i-fillup/databases/(default)/documents'


def token(uid):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
    return '.'.join([encode({'alg': 'none', 'typ': 'JWT'}), encode({
        'sub': uid, 'user_id': uid, 'aud': 'demo-i-fillup',
        'iss': 'https://securetoken.google.com/demo-i-fillup',
        'iat': int(time.time()), 'exp': int(time.time()) + 3600,
        'firebase': {'sign_in_provider': 'password'},
    }), ''])


def field(value):
    if isinstance(value, bool):
        return {'booleanValue': value}
    if isinstance(value, int):
        return {'integerValue': str(value)}
    if isinstance(value, float):
        return {'doubleValue': value}
    if isinstance(value, list):
        return {'arrayValue': {'values': [field(item) for item in value]}}
    if isinstance(value, dict):
        return {'mapValue': {'fields': {k: field(v) for k, v in value.items()}}}
    return {'stringValue': value}


def request(method, path, uid, data=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if uid:
        headers['Authorization'] = 'Bearer ' + token(uid)
    body = None if data is None else json.dumps({'fields': {
        key: ({'timestampValue': '2026-10-31T12:00:00Z'} if key.endswith('At') else field(value))
        for key, value in data.items()
    }}).encode()
    req = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            status = response.status
    except urllib.error.HTTPError as error:
        status = error.code
    assert status == expected, f'{method} {path}: expected {expected}, got {status}'


suffix = uuid.uuid4().hex
host = 'host-' + suffix
# One place per account: a place's ID must be its owner's UID.
place_id = host
request_id = 'request-' + suffix
place = dict(name='Test water', area='Zurich', host='Host', private=True,
             price='Free', description='Test', openingTimes='Always',
             latitude=47.3, longitude=8.5, photo='', vehicles=['campervan'],
             services=['farmShop'], businessInfo='Eggs', website='https://hof.ch',
             ownerUid=host, isActive=True, createdAt='', updatedAt='')
request('PATCH', '/waterPlaces/second-' + suffix, host, place, 403)
request('PATCH', '/waterPlaces/' + place_id, host, place)
request('PATCH', '/waterPlaces/' + place_id, host, place, 403)
request('PATCH', '/waterPlaces/forged-' + suffix, 'stranger', place, 403)
request('PATCH', '/waterPlaces/unsigned-' + suffix, None, place, 403)
refill = dict(placeId=place_id, placeName='Test water', hostUid=host,
              requesterUid='traveler', liters=50, message='Hello', status='pending',
              requester=dict(name='Lea', vehicle='Van', phone='', about='', photo=''),
              createdAt='', updatedAt='')
request('PATCH', '/refillRequests/' + request_id, 'traveler', refill)
request('PATCH', '/refillRequests/forged-' + suffix, 'traveler', dict(refill, hostUid='stranger'), 403)
request('PATCH', '/refillRequests/zero-' + suffix, 'traveler', dict(refill, liters=0), 403)
request('GET', '/refillRequests/' + request_id, 'traveler')
request('GET', '/refillRequests/' + request_id, host)
request('GET', '/refillRequests/' + request_id, 'stranger', expected=403)
request('GET', '/refillRequests/' + request_id, None, expected=403)
status_path = '/refillRequests/' + request_id + '?updateMask.fieldPaths=status&updateMask.fieldPaths=updatedAt'
request('PATCH', status_path, 'traveler', dict(status='accepted', updatedAt=''), 403)
request('PATCH', status_path, host, dict(status='accepted', updatedAt=''))
request('PATCH', status_path, host, dict(status='declined', updatedAt=''), 403)
hide_path = '/refillRequests/' + request_id + '?updateMask.fieldPaths=hostHidden&updateMask.fieldPaths=updatedAt'
request('PATCH', hide_path, 'traveler', dict(hostHidden=True, updatedAt=''), 403)
request('PATCH', hide_path, host, dict(hostHidden=True, updatedAt=''))
mine_path = '/refillRequests/' + request_id + '?updateMask.fieldPaths=requesterHidden&updateMask.fieldPaths=updatedAt'
request('PATCH', mine_path, host, dict(requesterHidden=True, updatedAt=''), 403)
request('PATCH', mine_path, 'traveler', dict(requesterHidden=True, updatedAt=''))
request('DELETE', '/waterPlaces/' + place_id, 'stranger', expected=403)
request('DELETE', '/waterPlaces/' + place_id, host)
print('21 Firestore rules checks passed (local emulator only).')
