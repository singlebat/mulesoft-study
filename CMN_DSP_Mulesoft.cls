public class CMN_DSP_Mulesoft {
    
    /**
     * 追加用禁則文字 変換前
     * %: 左記の文字が含まれている場合にTAM側で左記文字が弾かれ、Rest−APIまでたどり着くことができないため変換対象とする。
     */
    private static final List<String> CONVERT_ILLEGAL_CHARSET_BEFORE = new List<String>{ '%' };
    /**
     * 追加用禁則文字 変換後
     */
    private static final List<String> CONVERT_ILLEGAL_CHARSET_AFTER = new List<String>{ '％' };

    /**
     * @description httpRequestメソッドで発生したExceptionを表す.
     */
    public class CMN_UTL_Callout_HttpRequest_Exception extends Exception {}

   /**
     * @description POSTリクエストの送信を行う.
     * @param endpoint MulesoftのURL
     * @param inputMap XASサービスパラメータ
     * @param deserializeType タイプ
     * @param timeout_ms タイムアウト時間（ミリ秒）
     * @return レスポンス（deserializeType型）
     */
     @future(callout=true)
    public static void callPostXAS(final String jsonStr, final integer timeout_ms) {
        // DSP_DTO_MuleSfotInput inputData
        httpRequest(jsonStr,timeout_ms);
    }

	public static void callPostXASTest(final String jsonStr, final integer timeout_ms) {
        // DSP_DTO_MuleSfotInput inputData
        httpRequest(jsonStr,timeout_ms);
    }
    
    private static void httpRequest(final String jsonStr, final integer timeout_ms) {

        System.debug('CMN_DSP_Mulesoft httpRequest START');
        string correlationID = getRamdamStr();
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('jwt','{!$Credential.AuthorizationHeaderValue}');
        req.setHeader('X-Correlation-ID',correlationID);
        req.setHeader('Content-Type', 'application/json');

        String url = 'callout:MuleXASProxy_ST/dev/xas-1/mst/api/v1/address-query?zipCde=1050001';
        req.setEndpoint(url);
        req.setMethod('GET');

        /* 疎通確認用のエンドポイントはGETなので一旦、コメントアウト
        req.setMethod('POST');
        
        if(jsonStr != null) {
            req.setBody(CMN_UTL_Converter.convertByArraysOfIndex(JSON.serialize(jsonStr), CONVERT_ILLEGAL_CHARSET_BEFORE, CONVERT_ILLEGAL_CHARSET_AFTER));
        }
        */
		req.setTimeout(timeout_ms);
        Datetime beforedatetime = Datetime.now();
        System.debug('>>> Invoke start -> ' + beforedatetime.format('HH:mm:ss.SSS'));
        HttpResponse res = new HttpResponse();
        try {
            res = http.send(req);
        } catch (Exception e) {
            e.setMessage(e.getMessage() + getMoreMessage(correlationID, res));
            throw e;
        }
        Datetime afterdatetime = Datetime.now();
        Long termdatetime = afterdatetime.getTime() - beforedatetime.getTime();
        System.debug('>>> Invoke end -> ' + afterdatetime.format('HH:mm:ss.SSS') + ' (' + string.valueOf(termdatetime) + ')');
        System.debug('>>> Endpoint -> ' + req.getEndpoint());
        System.debug('>>> Response Body -> ' + res.getBody());
        System.debug('>>> HTTP Status Message -> ' + res.getStatus());
        System.debug('>>> HTTP Status Code -> ' + res.getStatusCode());

        if (res.getStatusCode() == 200){
            System.debug('CMN_DSP_Mulesoft httpRequest END');
        } else {
            System.debug(String.format(
                    'REST-API 呼び出しの実行に失敗しました。\nEndpoint:{0}\nStatus:{1}\nBody:{2}',
                    new String[]{req.getEndpoint(), res.getStatus(), res.getBody()}));
            System.debug('CMN_DSP_Mulesoft httpRequest END');

            CMN_UTL_Callout_HttpRequest_Exception ce = new CMN_UTL_Callout_HttpRequest_Exception();
            ce.setMessage(getMoreMessage(correlationID, res));

            throw ce;
        }
    }
    private static string getMoreMessage(String correlationID, HttpResponse res) {
        String userid = UserInfo.getUserId();
        User u = [SELECT FederationIdentifier FROM User WHERE Id = :userid];
        String msg = '';
        msg = msg + '\r\n・CorrelationID:' + correlationID;
        msg = msg + '\r\n・AANETID（FederationIdentifier）:' + u.FederationIdentifier;
        msg = msg + '\r\n・HttpResponse.StatusCode:' + res.getStatusCode();
        return msg;
    }
    public static string getRamdamStr() {
        string charlist = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        string resStr = '';
        integer position;
        for (integer i=0; i < 13; i++) {
            position = integer.valueof(string.valueof(Math.roundToLong((charlist.length()-1)*Math.random())));
            resStr += charlist.substring(position, position+1);
        }
        return resStr;
    }

    /**
     * 疎通確認用(マニュアルソースと同じ)
     */
    public static void getConnectXas() {
        String correlationID = getRamdamStr();
        String url = 'callout:MuleXASProxy_ST/dev/xas-1/mst/api/v1/address-query?zipCde=1050001';

        Http http = new Http();
        HttpRequest req = new HttpRequest();

                        
        // ヘッダー名を指定して、JWTを埋め込む設定。変数を設定することで実行時にフレームワークがJWTを生成し設定する。	
        // {!$...}は、指定ログイン情報の設定から生成されるJWTを埋め込む変数である。
        // 変数は実行時にSalesforceのフレームワーク内でJWTが設定する。
        req.setHeader('jwt','{!$Credential.AuthorizationHeaderValue}');
        //トレース用に複数のAPI間で利用する共通のセッションIDを設定する。
        // 推奨はUserInfo.getSessionId()だが、特定の条件（Lightningページからの通信）では値を取得できないため、個別ロジックで生成し設定する。		
        // その他には認証プロバイダ設定をすることでOauthでログインしたセッションIDを取得できるが、用途はトレースのためだけなので個別ロジックで設定する。	
        req.setHeader('X-Correlation-ID', correlationID);
        req.setHeader('Content-Type','application/json');				
        req.setEndpoint(url);
        req.setMethod('GET');

        System.debug('>>> jwt_before -> ' + req.getHeader('jwt'));

        Datetime beforedatetime = Datetime.now();
        System.debug('>>> Invoke start -> ' + beforedatetime.format('HH:mm:ss.SSS'));
        HttpResponse res = http.send(req);
        Datetime afterdatetime = Datetime.now();
        Long termdatetime = afterdatetime.getTime() - beforedatetime.getTime();

        System.debug('>>> Invoke end -> ' + afterdatetime.format('HH:mm:ss.SSS') + ' (' + String.valueOf(termdatetime) + ')');
        System.debug('>>> Endpoint -> ' + req.getEndpoint());
        System.debug('>>> X-Correlation-ID -> ' + req.getHeader('X-Correlatio-ID'));
        System.debug('>>> Response Body -> ' +res.getBody());
        System.debug('>>> HTTP Status Message -> ' + res.getStatus());
        System.debug('>>> HTTP Status Code -> ' + res.getStatusCode());
    }
    
}