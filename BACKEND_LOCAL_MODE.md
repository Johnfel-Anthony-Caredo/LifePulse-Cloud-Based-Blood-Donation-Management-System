# LifePulse Local Backend Mode

The app now defaults to a local in-memory backend so development can continue
while the new AWS account is not ready.

## Default mode

Run the app normally. It will skip Amplify configuration and use seeded local
data for:

- hospitals
- donors
- blood requests
- appointments
- donation history
- notifications
- local sign in/sign up behavior

Any email/password is accepted in local mode. Use the role toggle on the login
screen to enter either the admin or donor side.

Useful demo accounts:

- Admin: `admin@lifepulse.local`
- Donor: `donor@lifepulse.local`

## AWS mode later

After the new AWS backend is recreated, run Flutter with:

```bash
--dart-define=USE_AWS_BACKEND=true
```

That switches services back to Amplify-backed calls.
