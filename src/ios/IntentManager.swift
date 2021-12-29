 /*
  * Copyright (c) 2021 Elastos Foundation
  *
  * Permission is hereby granted, free of charge, to any person obtaining a copy
  * of this software and associated documentation files (the "Software"), to deal
  * in the Software without restriction, including without limitation the rights
  * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  * copies of the Software, and to permit persons to whom the Software is
  * furnished to do so, subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall be included in all
  * copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  * SOFTWARE.
  */

 import Foundation
 import SwiftJWT
 import AnyCodable
 import PopupDialog
 import ElastosDIDSDK

//TODO:: Redundant conformance with DID plugin need to fix.
//  extension AnyCodable : SwiftJWT.Claims {}

 @objc(AppDelegate)
 extension AppDelegate {
    open override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        IntentManager.getShareInstance().setIntentUri(url);
        return true;
    }

    open override func application(_ application: UIApplication,
                continue userActivity: NSUserActivity,
                restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Get URL from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL else {
            return false
        }

        IntentManager.getShareInstance().setIntentUri(incomingURL);
        return true;
    }
 }

 class Intent {
    @objc dynamic var app_id = "";
    @objc dynamic var action = "";

    init(_ app_id: String, _ action: String) {
        self.app_id = app_id;
        self.action = action;
    }
 }

 class IntentInfo {
    @objc static let JWT = 1;
    @objc static let URL = 2;

    @objc static let REDIRECT_URL = "redirecturl";
    @objc static let CALLBACK_URL = "callbackurl";

    @objc dynamic var action: String; // Full action as given by the dapp, including domain and action
    @objc dynamic var params: String?;
    @objc dynamic var intentId: Int64 = 0;
    @objc dynamic var callbackId: String? = nil;


    @objc dynamic var responseJwt: String? = nil // JWT output generated by the dapp or service that has handled the intent.
    @objc dynamic var originalJwtRequest: String? = nil
    @objc dynamic var redirecturl: String?;
    @objc dynamic var callbackurl: String?;
    @objc dynamic var redirectappurl: String?;
    @objc dynamic var aud: String?;
    @objc dynamic var req: String?;
    @objc dynamic var type = URL;


    init(_ action: String, _ params: String?, _ callbackId: String?) {
        self.action = action;
        self.params = params;
        self.intentId = Int64(Date().timeIntervalSince1970);
        self.callbackId = callbackId;
    }
 }

 class ShareIntentParams {
    var title: String?
    var url: URL?
 }

 class OpenUrlIntentParams {
    var url: URL?
 }

 class IntentManager {
    static let MAX_INTENT_NUMBER = 20;
    static let JWT_SECRET = "secret";
    private static let LOG_TAG = "IntentManager"

    private var intentContextList = [Int64: IntentInfo]();
    private var intentUriList = [URL]();


    private static var intentManager: IntentManager?;
    private var listenerReady = false;
    private var callbackId: String?;
    private var commandDelegate:CDVCommandDelegate?;
    private var internalIntentFilters: [String] = [String]();
    private var intentRedirecturlFilter: String?;

    private var viewController: CDVViewController?;

    init() {
        IntentManager.intentManager = self;
    }


    static func getShareInstance() -> IntentManager {
        if (IntentManager.intentManager == nil) {
            IntentManager.intentManager = IntentManager();
        }
        return IntentManager.intentManager!;
    }

    func setViewController(_ viewController: CDVViewController, _ commandDelegate: CDVCommandDelegate) {
        listenerReady = false;
        self.viewController = viewController;
        self.commandDelegate = commandDelegate;
        let filters = viewController.settings["internalintentfilters"] as? String;
        if (filters != nil) {
            let items = filters!.split(separator: " ");
            for item in items {
                internalIntentFilters.append(String(item))
            }
        }

        intentRedirecturlFilter = viewController.settings["intentredirecturlfilter"] as? String;
    }

    func isInternalIntent(_ action: String) -> Bool {
        for internalIntentFilter in internalIntentFilters {
            if (action.hasPrefix(internalIntentFilter)) {
                return true;
            }
        }

        return false;
    }

    func isJSONType(_ str: String) -> Bool {
        let _str = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if (_str.hasPrefix("{") && _str.hasSuffix("}"))
                || (_str.hasPrefix("[") && _str.hasSuffix("]")) {
            return true
        }
        return false
     }

    public func openUrl(_ urlString: String) {
         let url = URL(string: urlString)!
         if #available(iOS 10, *) {
             UIApplication.shared.open(url, options: [:],
                                         completionHandler: {
                                         (success) in
             })
         }
         else {
             UIApplication.shared.openURL(url);
         }
     }

    func alertDialog(_ title: String, _ msg: String) {
        func doOKHandler(alerAction:UIAlertAction) {

        }

        let alertController = UIAlertController(title: title,
                                               message: msg,
                                               preferredStyle: UIAlertController.Style.alert)
        let sureAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: doOKHandler)
        alertController.addAction(sureAlertAction)

        DispatchQueue.main.async {
            self.viewController!.present(alertController, animated: true, completion: nil)
        }
    }

    private func initializeDIDBackend() throws {
        try DIDBackend.initialize(DefaultDIDAdapter("https://api.elastos.io/eid"));
    }

    func setIntentUri(_ uri: URL) {
        if !uri.absoluteString.contains("redirecturl") && uri.absoluteString.contains("/intentresponse") {
            receiveExternalIntentResponse(uri: uri)
        }
        else if (listenerReady) {
            doIntentByUri(uri)
        }
        else {
            intentUriList.append(uri);
        }
    }

    func setListenerReady(_ callbackId: String) {
        self.callbackId = callbackId;
        listenerReady = true;

        for uri in intentUriList {
            IntentManager.getShareInstance().doIntentByUri(uri);
        }
        intentUriList.removeAll();
    }

    func onReceiveIntent(_ info: IntentInfo) {
        if (self.callbackId == nil) {
            return;
        }
        addToIntentContextList(info);

        let ret = [
            "action": info.action,
            "params": info.params,
            "intentId": info.intentId,
            "originalJwtRequest": info.originalJwtRequest
            ] as [String : Any?]
        let result = CDVPluginResult(status: CDVCommandStatus_OK,
                                     messageAs: ret as [String : Any]);
        result?.setKeepCallbackAs(true);
        self.commandDelegate!.send(result, callbackId:self.callbackId);
    }

    func onReceiveIntentResponse(_ info: IntentInfo) {
        if (info.callbackId != nil) {
            var ret = [
                "action": info.action,
                "result": info.params,
            ] as [String : Any?]
            if (info.responseJwt != nil) {
                ret["responseJWT"] = info.responseJwt;
            }

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ret as [String : Any]);
            result?.setKeepCallbackAs(false);
            self.commandDelegate!.send(result, callbackId: info.callbackId)
        }
    }

    //TODO:: synchronized?
    private func addToIntentContextList(_ info: IntentInfo) {
        let intentInfo = intentContextList[info.intentId];
        if (intentInfo != nil) {
            return
        }

        intentContextList[info.intentId] = info;
    }

    public static func parseJWT(_ jwt: String) throws -> [String: Any]? {
        let jwtDecoder = SwiftJWT.JWTDecoder.init(jwtVerifier: .none)
        let data = jwt.data(using: .utf8) ?? nil
        if data == nil {
            throw "parseJWT error!"
        }
        let decoded = try? jwtDecoder.decode(SwiftJWT.JWT<AnyCodable>.self, from: data!)
        if decoded == nil {
            throw "parseJWT error!"
        }
        return decoded?.claims.value as? [String: Any]
    }

    func getParamsByJWT(_ jwt: String, _ info: IntentInfo) throws {
        var jwtPayload = try IntentManager.parseJWT(jwt)
        if jwtPayload == nil {
            throw "getParamsByJWT error!"
        }

        jwtPayload!["type"] = "jwt";
        info.params = DictionarytoString(jwtPayload!) ?? "";

        if (jwtPayload!["iss"] != nil) {
            info.aud = (jwtPayload!["iss"] as! String);
        }
        if let appid = jwtPayload!["appid"] {
            // info.req = (jwtPayload!["appid"] as! String);
            // Compatible with int and string.(Usually the appid is string)
            info.req = "\(appid)"
        }
        if (jwtPayload![IntentInfo.REDIRECT_URL] != nil) {
            info.redirecturl = (jwtPayload![IntentInfo.REDIRECT_URL] as! String);
        }
        else if (jwtPayload![IntentInfo.CALLBACK_URL] != nil) {
            info.callbackurl = (jwtPayload![IntentInfo.CALLBACK_URL] as! String);
        }
        info.type = IntentInfo.JWT
        info.originalJwtRequest = jwt
    }

    func getParamsByUri(_ params: [String: String], _ info: IntentInfo) {
        var json = Dictionary<String, Any>()
        for (key, value) in params {
            if (key == IntentInfo.REDIRECT_URL) {
                info.redirecturl = value;
            }
            else if (key == IntentInfo.CALLBACK_URL) {
                info.callbackurl = value;
            }
            else if (key == "iss") {
                info.aud = value;
            }
            else if (key == "appid") {
                info.req = value;
            }

            if isJSONType(value) {
                let jsonData:Data = value.data(using: .utf8)!
                do {
                    json[key] = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                } catch (let e) {
                    print(e.localizedDescription)
                }
            }
            else {
                json[key] = value
            }
        }
        info.type = IntentInfo.URL
        info.params = DictionarytoString(json) ?? ""
    }

    func parseIntentUri(_ _uri: URL, _ callbackId: String?) throws -> IntentInfo? {
        var info: IntentInfo? = nil;
        var uri = _uri;
        var url = uri.absoluteString;

        if (!url.contains("://")) {
            throw "The url: '\(url)' is error!";
        }

        if (url.hasPrefix("elastos://") && !url.hasPrefix("elastos:///")) {
            url = "elastos:///" + (url as NSString).substring(from: 10);
            uri = URL(string: url)!;
        }
        var pathComponents = uri.pathComponents;
        pathComponents.remove(at: 0);

        if (pathComponents.count > 0) {
            let host = uri.host
            var action: String? = nil;
            if (host == nil || host!.isEmpty) {
                throw "The action: '\(pathComponents[0])' is invalid!";
            }
            else {
                action = uri.scheme! + "://" + uri.host! + "/" +  pathComponents[0];
            }
            let params = uri.parametersFromQueryString;

            info = IntentInfo(action!, nil, callbackId)

            if (params != nil && params!.count > 0) {
                getParamsByUri(params!, info!);
            }
            else if (pathComponents.count == 2) {
                try getParamsByJWT(pathComponents[1], info!);
            }
        }
        return info;
    }

    func receiveIntent(_ uri: URL, _ callbackId: String?) throws {
        let info = try parseIntentUri(uri, callbackId);
        if (info != nil && info!.params != nil) {
            // We are receiving an intent from an external application. Do some sanity check.
            try checkExternalIntentValidity(info: info!) { [self]
                isValid, errorMessage in
                if isValid {
                    do {
                        try self.onReceiveIntent(info!)
                    } catch (let e) {
                        print(e.localizedDescription)
                    }
                }
                else {
                    print(errorMessage ?? "onReceiveIntent error")
                    self.alertDialog("Invalid intent received", "The received intent could not be handled and returned the following error: " + errorMessage!);
                }
            }
        }
    }

    func doIntentByUri(_ uri: URL) {
        do {
            try receiveIntent(uri, nil);
        }
        catch let error {
            print("doIntentByUri: \(error)");
        }
    }

    typealias OnExternalIntentValidCallback = (_ isValid: Bool, _ errorMessage: String?)->Void

    private func checkExternalIntentValidity(info: IntentInfo, onExternalIntentValid: @escaping OnExternalIntentValidCallback) throws {
        // If the intent contains an appDid param and a redirectUrl (or callbackurl), then we must check that they match.
        // This means that the app did document from the ID chain must contain a reference to the expected redirectUrl/callbackUrl.
        // This way, we make sure that an application is not trying to act on behalf of another one by replacing his DID.
        // Ex: access to hive vault.
        if info.redirecturl != nil || info.callbackurl != nil {
            do {
                let params = info.params!.toDict()!
                if params.keys.contains("appdid") {
                    // So we need to resolve this DID from chain and make sure that it matches the target redirect/callback url
                    try checkExternalIntentValidityForAppDID(info: info, appDid: params["appdid"]! as! String, onExternalIntentValid: onExternalIntentValid)
                } else {
                    onExternalIntentValid(true, nil)
                }
            } catch (let e) {
                print(e.localizedDescription)
                onExternalIntentValid(false, "Intent parameters must be a JSON object")
            }
        }
        else {
            onExternalIntentValid(true, nil)
        }
    }

    private func checkExternalIntentValidityForAppDID(info: IntentInfo, appDid: String, onExternalIntentValid: @escaping OnExternalIntentValidCallback) throws {
        try initializeDIDBackend()

        DispatchQueue.init(label: "CheckExtIntentValidity").async {
            do {
                if let didDocument = try DID(appDid).resolve(true) {
                    // DID document found. Look for the #native credential
                    if let nativeCredential = try didDocument.credential(ofId: "#native") {
                        // Check redirect url, if any
                        if (info.redirecturl != nil && info.redirecturl != "") {
                            if let onChainRedirectUrl = nativeCredential.subject?.getPropertyAsString(ofName:"redirectUrl") {
                                // We found a redirect url in the app DID document. Check that it matches the one in the intent
                                if (info.redirecturl!.hasPrefix(onChainRedirectUrl)) {
                                    // Everything ok.
                                    onExternalIntentValid(true, nil)
                                }
                                else {
                                    onExternalIntentValid(false, "The registered redirect url in the App DID document ("+onChainRedirectUrl+") doesn't match with the received intent redirect url")
                                }
                            }
                            else {
                                onExternalIntentValid(false, "No redirectUrl found in the app DID document. Was the 'redirect url' configured and published on chain, using the developer tool dApp?")
                            }
                        }
                        // Check callback url, if any
                        else if (info.callbackurl != nil && info.callbackurl != "") {
                            if let onChainCallbackUrl = nativeCredential.subject?.getPropertyAsString(ofName:"callbackUrl") {
                                // We found a callback url in the app DID document. Check that it matches the one in the intent
                                if (info.callbackurl!.hasPrefix(onChainCallbackUrl)) {
                                    // Everything ok.
                                    onExternalIntentValid(true, nil)
                                }
                                else {
                                    onExternalIntentValid(false, "The registered callback url in the App DID document ("+onChainCallbackUrl+") doesn't match with the received intent callback url")
                                }
                            }
                            else {
                                onExternalIntentValid(false, "No callbackUrl found in the app DID document. Was the 'callback url' configured and published on chain, using the developer tool dApp?")
                            }
                        }
                        else {
                            // Everything ok. No callback url or redirect url, so we don't need to check anything.
                            onExternalIntentValid(true, nil)
                        }
                    }
                    else {
                        onExternalIntentValid(false, "No #native credential found in the app DID document. Was the 'redirect/callback url' configured and published on chain, using the developer tool dApp?")
                    }
                }
                else { // Not found
                    onExternalIntentValid(false, "No DID found on chain matching the application DID "+appDid)
                }
            }
            catch (let e) {
                onExternalIntentValid(false, e.localizedDescription)
            }
        }
    }

    private func addParamLinkChar(_ url: String) -> String {
        var url = url;
        if (url.contains("?")) {
            url = url + "&"
        }
        else {
            url = url + "?"
        }
        return url;
    }

    // Opposite of parseIntentUri().
    // From intent info params to url params.
    // Ex: info.params = "{a:1, b:{x:1}}" returns url?a=1&b={x:1}
    private func createUriParamsFromIntentInfoParams(_ info: IntentInfo) throws -> String {
        // Convert intent info params into a serialized json string for the target url
        var params = [String: Any]();
        if (info.params != nil) {
            let dict = info.params!.toDict()
            if (dict != nil) {
                params = dict!;
            }
        }

//        params["appdid"] = appManager.getAppInfo(info.fromId)!.did

        var url = info.action;
        for (key , value) in params {
            let serializedValue = anyToJsonFieldString(value)
            url = addParamLinkChar(url);
            url += key + "=" + serializedValue.encodingQuery()
        }

        // If there is no redirect url, we add one to be able to receive responses
        if !params.keys.contains("redirecturl") {
            if (intentRedirecturlFilter == nil) {
                alertDialog("Invalid intent redirect url filter", "Please set 'IntentRedirecturlFilter' preference in app's config.xml.");
            }
            else {
                url = addParamLinkChar(url);
                url = url + "redirecturl=" + intentRedirecturlFilter! + "/intentresponse%3FintentId=\(info.intentId)"; // Ex: https://diddemo.elastos.org/intentresponse?intentId=xxx
            }
        }

        print("INTENT DEBUG: " + url)
        return url
    }

    func createUnsignedJWTResponse(_ info: IntentInfo, _ result: String) throws -> String? {
        var claims = result.toDict();
        if (claims == nil) {
            throw "createJWTResponse: result error!";
        }
        claims!["req"] = info.req;
        let jwt = SwiftJWT.JWT<AnyCodable>(claims: AnyCodable(claims!))
        let jwtEncoder = SwiftJWT.JWTEncoder(jwtSigner: .none)
        let encodedData = try jwtEncoder.encode(jwt)
        return String(data:encodedData, encoding: .utf8)
    }

    func createUrlResponse(_ info: IntentInfo, _ result: String) -> String? {
        var ret = result.toDict();
        if ret == nil {
            ret = [String: Any]();
        }
        if (info.req != nil) {
            ret!["req"] = info.req;
        }
        if (info.aud != nil) {
            ret!["aud"] = info.aud;
        }
        ret!["iat"] = Int64(Date().timeIntervalSince1970)/1000;
        ret!["method"] = info.action;
        return DictionarytoString(ret!);
    }

    func postCallback(_ name: String, _ value: String, _ callbackurl: String) throws {

        let url = URL(string: callbackurl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST";
        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type");
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let parameters: [String: String] = [
            name: value
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in

            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    //                throw AppError.error("postCallback error:" + error ?? "Unknown error");
                    return
            }

            if !((200 ... 299) ~= response.statusCode) {                    // check for http errors
                print("Error - statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")

                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                }
            }
            else {
                print("Intent callback url responsed with success (2** http code)")
            }
        })

        task.resume()
    }

    func getResultUrl(_ url: String, _ result: String) -> String {
        var param = "?result=";
        if (url.contains("?")) {
            param = "&result=";
        }
        return URL(string: url + param + result.encodingQuery())!.absoluteString;
    }

    private func getJWTRedirecturl(_ url: String, _ jwt: String) -> String {
        let index = url.indexOf("?");
        if (index != -1) {
            let params = url.subString(from: index);
            let url = url.subString(to: index);
            return url + "/" + jwt + params;
        }
        else {
            return url + "/" + jwt;
        }
    }

    /**
     * Helper class to deal with app intent result types that can be either JSON objects with raw data,
     * or JSON objects with "jwt" special field.
     */
    private class IntentResult {
        let rawResult: String
        var payload: Dictionary<String, Any>? = nil
        var jwt: String? = nil

        init(rawResult: String) throws {
            self.rawResult = rawResult

            if let resultAsJson = rawResult.quotedJsonStringKeys().toDict() {
                if resultAsJson.keys.contains("jwt") {
                    // The result is a single field named "jwt", that contains an already encoded JWT token
                    jwt = resultAsJson["jwt"] as? String
                    if jwt != nil {
                        payload = try parseJWT(jwt!)
                    }
                    else {
                        payload = Dictionary<String, Any>() // Nil response -> Empty JSON payload
                    }
                }
                else {
                    // The result is a simple JSON object
                    payload = resultAsJson
                }
            }
            else {
                // Unable to understand the passed result as JSON
                payload = nil
            }
        }

        func payloadAsString() -> String {
            return DictionarytoString(payload) ?? "{}"
        }

        func isAlreadyJWT() -> Bool {
            return jwt != nil
        }
    }

    func sendIntentResponse(_ result: String, _ intentId: Int64) throws {
        let info = intentContextList[intentId]
        if (info == nil) {
            throw "Intent with ID " + intentId.value + " doesn't exist!"
        }
        intentContextList[intentId] = nil;

        // The result object can be either a standard json object, or a {jwt:JWT} object.
        let intentResult = try IntentResult(rawResult: result)

        var urlString = info!.redirecturl
        if (urlString == nil) {
            urlString = info!.callbackurl
        }

        // If there is a provided URL callback for the intent, we want to send the intent response to that url
        if (urlString != nil && urlString != "") {
            var jwt: String? = nil
            if intentResult.isAlreadyJWT() {
                jwt = intentResult.jwt
            }
            else {
                // App did not return a JWT, so we return an unsigned JWT instead
                jwt = try createUnsignedJWTResponse(info!, result)
            }


            // Response url can't be handled by trinity. So we either call an intent to open it, or HTTP POST data
            if (info!.redirecturl != nil) {
                if intentResult.isAlreadyJWT() {
                    urlString = getJWTRedirecturl(info!.redirecturl!, jwt!)
                }
                else {
                    urlString = getResultUrl(urlString!, intentResult.payloadAsString()) // Pass the raw data as a result= field
                }
                openUrl(urlString!)
            }
            else if (info!.callbackurl != nil && info!.callbackurl != "") {
                if (intentResult.isAlreadyJWT()) {
                    try postCallback("jwt", jwt!, info!.callbackurl!)
                }
                else {
                    try postCallback("result", intentResult.payloadAsString(), info!.callbackurl!)
                }
            }
        }
        else if (info!.callbackId != nil) {
            info!.params = intentResult.payloadAsString()
            // If the called dapp has generated a JWT as output, we pass the decoded payload to the calling dapp
            // for convenience, but we also forward the raw JWT as this is required in some cases.
            if intentResult.isAlreadyJWT() {
                info!.responseJwt = intentResult.jwt
            }
            onReceiveIntentResponse(info!)
        }
    }

    private func extractShareIntentParams(_ info: IntentInfo) -> ShareIntentParams? {
        // Extract JSON params from the share intent. Expected format is {title:"", url:""} but this
        // could be anything as this is set by users.
        guard let params = info.params else {
            print("Share intent params are not set!")
            return nil
        }

        guard let fields = params.toDict() else {
            print("Share intent parameters are not JSON format")
            return nil
        }

        let shareIntentParams = ShareIntentParams()

        shareIntentParams.title  = fields["title"] as? String

        if let url = fields["url"] as? String {
            if let parsedUrl = URL(string: url) {
                shareIntentParams.url = parsedUrl
            }
        }

        return shareIntentParams
    }

    func sendNativeShareAction(_ info: IntentInfo) {
        if (self.viewController == nil) {
            return;
        }

        if let extractedParams = extractShareIntentParams(info) {
            var activityItems: [Any] = [];

            if let title = extractedParams.title {
                activityItems.append(title)
            }
            if let url = extractedParams.url {
                activityItems.append(url)
            }

            let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
            self.viewController!.present(vc, animated: true, completion: nil)
        }
    }

    private func extractOpenUrlIntentParams(info: IntentInfo) -> OpenUrlIntentParams? {
        // Extract JSON params from the open url intent. Expected format is {url:""}.
        if info.params == nil {
            print("Openurl intent params are not set!")
            return nil
        }

        if let jsonParams = info.params!.toDict() {
            let openUrlIntentParams = OpenUrlIntentParams()

            if jsonParams.keys.contains("url"), let url = jsonParams["url"] as? String {
                openUrlIntentParams.url = URL(string: url)
            }
            return openUrlIntentParams
        }
        else    {
            print("Openurl intent parameters are not JSON format")
            return nil
        }
    }

    func sendNativeOpenUrlAction(info: IntentInfo) {
        if let extractedParams = extractOpenUrlIntentParams(info: info) {
            // Can't send an empty open url action
            if extractedParams.url == nil {
                return
            }

            UIApplication.shared.open(URL(string: extractedParams.url!.absoluteString)!, options: [:], completionHandler: nil)
        }
    }

    public func receiveExternalIntentResponse(uri: URL) {
        let url = uri.absoluteString;
        print("RECEIVED: " + url)

        var resultStr: String? = nil
        if (url.contains("result=")) {
            // Result received as a raw string / raw json string
            resultStr = uri.parametersFromQueryString!["result"]
        }
        else {
            // Consider the received result as a JWT token
            resultStr = "{jwt:\"" + uri.lastPathComponent+"\"}";
        }
        print(resultStr ?? "error")

        do {
            var intentId: Int64 = -1;
            if (url.contains("intentId=")) {
                let id = uri.parametersFromQueryString!["intentId"]! as String
                intentId = try Int64(value: id)
            }
            try sendIntentResponse(resultStr!, intentId);
        } catch (let e) {
            print(e.localizedDescription)
        }
    }

    func sendIntent(_ info: IntentInfo) throws {
        if (info.action == "share") {
            sendNativeShareAction(info);
        }
        else if (info.action == "openurl") {
            sendNativeOpenUrlAction(info: info);
        }
        else {
            try sendIntentToExternal(info);
        }
    }

    func sendIntentToExternal(_ info: IntentInfo) throws {
        if !isJSONType(info.params!) {
            throw "Intent parameters must be a JSON object"
        }

        addToIntentContextList(info)
        let url = try createUriParamsFromIntentInfoParams(info) // info.action must be a full action url such as https://did.elastos.net/credaccess

        openUrl(url);
    }
 }
