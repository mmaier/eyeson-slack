# README

Slack Integration Meeting Service Application

## Setup

Triggers the slac oauth interface which asks for *permissions to add '/eyeson' command* to the dedicated slack team.
After successful authentication, an api key will be fetched via eyeson api.
At this time, the command is already available on slack, but the *api key must be activated* via api console. Otherwise an error will be returned to the user each time the command is being executed.

```shell
https://integrations.{environment}/slack/setup
```

## API Console

The team admin will be redirected automatically to the login/signup page of the api console after authentication.
Only the team admin must sign up to the api console just once in order to activate the api key.
The api key should be visible in the api console right after registration. At this moment the api key is activated and the slack command should work.

### License

The team admin is able to maintain a valid license via api console.

## Command

Just enter

```shell
/eyeson
```

in the slack chat input and the eyeson bot will send the join link to all users of the current channel.
Everybody within the channel will be able to join the meeting. Each channel has it's individual meeting link. There will be always the same link within one channel to avoid people joining different meetings.