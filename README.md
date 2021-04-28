---
title: IntentManager
description: This is an plugin for Elastos Cordova in order to manage external inter-app communications through "intents".
---

# @elastosfoundation/elastos-cordova-plugin-intent

This plugin defines a global `cordova.intentManager` object, which provides an API for intent manager library.

Although in the global scope, it is not available until after the `deviceready` event.

```js
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    console.log(intentManager);
}
```

## Usage
###  In typescript file
```ts
declare let intentManager: IntentPlugin.IntentManager;
```

---
## Installation

```bash
    cordova plugin add @elastosfoundation/elastos-cordova-plugin-intent
```

## Cofigure
### tsconfig.app.json
```json
    "types": [
        "@elastosfoundation/elastos-cordova-plugin-intent"
        ]
```

### config.xml
- Specific IntentRedirecturlFilter, with custom scheme for android vs https url for ios. such as
```xml
    <platform name="android">
        <preference name="IntentRedirecturlFilter" value="XXX://" />
        <config-file parent="/manifest/application/activity" target="AndroidManifest.xml">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="XXX" />
            </intent-filter>
        </config-file>
    </platform>

    <platform name="ios">
        <preference name="IntentRedirecturlFilter" value="https://XXX.sample.net" />
        <config-file parent="com.apple.developer.associated-domains" target="*-Debug.plist">
            <array>
                <string>applinks:XXX.sample.net</string>
            </array>
        </config-file>
        <config-file parent="com.apple.developer.associated-domains" target="*-Release.plist">
            <array>
                <string>applinks:XXX.sample.net</string>
            </array>
        </config-file>
    </platform>
```
about

- In android platform, need add "AndroidLaunchMode = singleTask" for receive external intent in the same activity.
```xml
    <platform name="android">
        <preference name="AndroidLaunchMode" value="singleTask" />
    </platform>
```
## Supported Platforms

- Android
- iOS

## Classes

<dl>
<dt><a href="#IntentManager">IntentManager</a></dt>
<dd></dd>
</dl>

## Typedefs
<dl>
<dt><a href="#ReceivedIntent">ReceivedIntent</a> : <code>Object</code></dt>
<dd><p>Information about an intent request.</p>
</dd>
</dl>

<a name="IntentManager"></a>

## IntentManager
**Kind**: global class

* [IntentManager](#IntentManager)
    * [.sendIntent(action, params](#IntentManager+sendIntent)
    * [.addIntentListener(callback: (msg: ReceivedIntent)=>void)](#IntentManager+addIntentListener)
    * [.sendIntentResponse(action, result, intentId)](#IntentManager+sendIntentResponse)

<a name="IntentManager+sendIntent"></a>

### appManager.sendIntent(action, params, onSuccess, [onError])
Send a intent by action.

**Kind**: instance method of [<code>IntentManager</code>](#IntentManager)

| Param | Type | Description |
| --- | --- | --- |
| action | <code>string</code> | The intent action. |
| params | <code>Object</code> | The intent params. |

<a name="IntentManager+addIntentListener"></a>

### appManager.addIntentListener(callback: (msg: ReceivedIntent)=>void)
Set intent listener for message callback.

**Kind**: instance method of [<code>IntentManager</code>](#IntentManager)

| Param | Type | Description |
| --- | --- | --- |
| callback | [<code>(msg: ReceivedIntent)=>void</code>](#onReceiveIntent) | The function receive the intent. |

<a name="IntentManager+sendIntentResponse"></a>

### appManager.sendIntentResponse(action, result, intentId, onSuccess, [onError])
Send a intent respone by id.

**Kind**: instance method of [<code>IntentManager</code>](#IntentManager)

| Param | Type | Description |
| --- | --- | --- |
| action | <code>string</code> | The intent action. |
| result | <code>Object</code> | The intent respone result. |
| intentId | <code>long</code> | The intent id. |

<a name="ReceivedIntent"></a>

## ReceivedIntent : <code>Object</code>
Information about an intent request.

**Kind**: IntentPlugin typedef
**Properties**

| Name | Type | Description |
| --- | --- | --- |
| action | <code>string</code> | The action requested from the receiving application. |
| params | <code>any</code> | Custom intent parameters provided by the calling application. |
| intentId | <code>number</code> | The intent id of the calling application. |
| originalJwtRequest? | <code>string</code> | In case the intent comes from outside essentials and was received as a JWT, this JWT is provided here. |
