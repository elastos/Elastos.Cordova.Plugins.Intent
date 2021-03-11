/*
* Copyright (c) 2018-2021 Elastos Foundation
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

/**
* This is an internal plugin for Elastos Cordova in order to manage internal and external
* inter-app communications through "intents".
* <br><br>
* Usage:
* <br>
* declare let cordovaIntent: IntentPlugin.Intent;
*/

declare namespace IntentPlugin {
    /**
     * Information about an intent request.
     */
    type ReceivedIntent = {
        /** The action requested from the receiving application. */
        action: string;
        /** Custom intent parameters provided by the calling application. */
        params: any;
        /** Application package id of the calling application. */
        intentId: number;
        /** In case the intent comes from outside elastOS and was received as a JWT, this JWT is provided here. */
        originalJwtRequest?: string;
    }

    /**
     * The class representing dapp manager for launcher.
     */
    interface Intent {
        /**
         * Send a intent by action.
         *
         * @param action     The intent action.
         * @param params     The intent params.
         */
        sendIntent(action: string, params?: any): Promise<any>;

        /**
         * Send a intent by url.
         *
         * @param url        The intent url.
         */
        sendUrlIntent(url: string): Promise<void>;

        /**
         * Add intent listener for intent callback.
         *
         * @param callback   The function to receive the intent.
         */
        addIntentListener(callback: (msg: ReceivedIntent)=>void);

        /**
         * Send a intent response by id.
         *
         * @param result     the intent result data to be sent to the caller of sendIntent().
         * @param intentId   The intent id.
         */
        sendIntentResponse(result: any, intentId: number): Promise<void>;
    }
}