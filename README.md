## Classes

<dl>
<dt><a href="#Intent">Intent</a></dt>
<dd></dd>
</dl>

## Typedefs

<a name="Intent"></a>

## Intent
**Kind**: global class

* [Intent](#Intent)
    * [new Intent()](#new_Intent_new)
    * [.sendIntent(action, params, onSuccess, [onError])](#Intent+sendIntent)
    * [.addIntentListener(callback)](#Intent+addIntentListener)
    * [.sendIntentResponse(action, result, intentId, onSuccess, [onError])](#Intent+sendIntentResponse)

<a name="new_Intent_new"></a>

### new Intent()
The class representing dapp manager for launcher.


<a name="Intent+sendIntent"></a>

### appManager.sendIntent(action, params, onSuccess, [onError])
Send a intent by action.

**Kind**: instance method of [<code>Intent</code>](#Intent)

| Param | Type | Description |
| --- | --- | --- |
| action | <code>string</code> | The intent action. |
| params | <code>Object</code> | The intent params. |
| onSuccess | <code>function</code> | The function to call when success. |
| [onError] | <code>function</code> | The function to call when error, the param is a String. Or set to null. |

<a name="Intent+addIntentListener"></a>

### appManager.addIntentListener(callback)
Set intent listener for message callback.

**Kind**: instance method of [<code>Intent</code>](#Intent)

| Param | Type | Description |
| --- | --- | --- |
| callback | [<code>onReceiveIntent</code>](#onReceiveIntent) | The function receive the intent. |

<a name="Intent+sendIntentResponse"></a>

### appManager.sendIntentResponse(action, result, intentId, onSuccess, [onError])
Send a intent respone by id.

**Kind**: instance method of [<code>Intent</code>](#Intent)

| Param | Type | Description |
| --- | --- | --- |
| action | <code>string</code> | The intent action. |
| result | <code>Object</code> | The intent respone result. |
| intentId | <code>long</code> | The intent id. |
| onSuccess | <code>function</code> | The function to call when success. |
| [onError] | <code>function</code> | The function to call when error, the param is a String. Or set to null. |

