# In-Game Feedback System

The room log has a `Feedback / Request` button with fixed categories:

- Bug
- Idea
- Stuck
- Mobile issue
- Controller issue
- More like this

The game stores each submission in the Roblox data store named `DontTouchItFeedback_v1`.

Each feedback entry includes:

- category and category label
- current room or hallway
- build version
- user id, username, and display name
- place id and server job id
- submission timestamp

## Viewing Feedback

For the current MVP, use Creator Hub's Data Stores Manager:

1. Open the experience in Creator Hub.
2. Go to `Configure`.
3. Open `Data Stores Manager`.
4. Select `DontTouchItFeedback_v1`.
5. Open keys with the `feedback_` prefix.

The key format is:

```text
feedback_<unix timestamp>_<user id>_<guid>
```

This keeps the newest feedback easy to identify by timestamp.

## Studio Testing

Roblox Studio data store access requires `Enable Studio Access to API Services` in the published experience's security settings. Use a separate test copy if you want to test feedback saves in Studio, because Studio can access the same data stores as the live game.

## Future Upgrade

The next upgrade should be an Open Cloud reader script or small dashboard that lists recent `DontTouchItFeedback_v1` entries outside Roblox Studio. Do not put Open Cloud API keys inside the Roblox game client or server scripts.
