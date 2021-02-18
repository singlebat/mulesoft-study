/**
 * 「アフラックへ提出」ボタンコントローラー
 * 
 * @author ACC菅沼 2020/10/06
 * @version 1.0
 */
public with sharing class DSP_CTL_AppSubmitAction {

    // TODO acc_李 Test
    // タイムアウト時間（ミリ秒）
    private final static integer TIMEOUT_MS = 120 * 1000;
    
    /**
     * 提出時の制御
     * 
     * @param recordId 代理店申請のレコードID
     * @return 処理結果DTO
     */
    @AuraEnabled
    public static DSP_DTO_AppSubmitActionResult submitAction(String recordId){ 

        DSP_DTO_AppSubmitActionResult dto = new DSP_DTO_AppSubmitActionResult();

        // 代理店申請の取得
        dto.application = DSP_DAO_Application.getApplicationById(recordId);

        DSP_BIZ_AppSubmitAction appBiz = new DSP_BIZ_AppSubmitAction();

        // チェック
        appBiz.submitActionCheck(dto);
        
        editBody(recordId);

        return dto;
    }

    @future(callout=true)
    public static void editBody(String recordId) {
        
        DSP_DTO_AppSubmitActionResult dto = new DSP_DTO_AppSubmitActionResult();
        DSP_BIZ_AppSubmitAction appBiz = new DSP_BIZ_AppSubmitAction();

        // 代理店申請の取得
        dto.application = DSP_DAO_Application.getApplicationById(recordId);

        // TODO acc_li test
        List<DSP_DataCoordinationApplication__c> insList = new List<DSP_DataCoordinationApplication__c>();

        if(dto.isError == false) {
            // レコード更新
            DSP_Application__c updateApplication = appBiz.createSubmitRecord(dto);
            Database.SaveResult result = DSP_DAO_Application.updateRecord(updateApplication);
            dto.addErroMessage(result);
        }

        if(dto.isError == false) {
            // 申請（連携用）の作成
            DSP_BIZ_SendIfData ifBiz = new DSP_BIZ_SendIfData();
            // 案２について修正　2021/01/20　ACC李   修正 Start
            //ifBiz.createSendIfData( dto.application.id, dto.application.RecordType.DeveloperName );
            insList = ifBiz.createSendIfData( dto.application.id, dto.application.DSP_ApplicationId__c);
            // 案２について修正　2021/01/20　ACC李   修正 End
        }

        // TODO acc_li Test
        // MuleSoftへデータ連携
        if(dto.isError == false) {

            // JSON用のMapを作成
            Map<String,Object> inputMap =  new Map<String,Object>();

            // JSON用Stringを作成
            String sendjson = '';

            // 申請（連携用）の作成
            DSP_BIZ_SendIfData ifBiz = new DSP_BIZ_SendIfData();

            // 申請（連携用）データを繰り返す
            for (DSP_DataCoordinationApplication__c dataCon : insList) {

                // 連携ファルドを追加
                sendjson = sendjson + dataCon.DSP_ApplicationFields__c;
            }

            //　コンテンツ情報を取得
            List<ContentDocumentLink> cde = ifBiz.getContentDocumentLink(recordId);

            for (ContentDocumentLink cd : cde) {

                 //ContentVersionを取得
                system.debug('ContentVersion取得前HeapSize：' + Limits.getHeapSize());
                ContentVersion cv =ifBiz.getConVerById(cd.ContentDocumentId);
                system.debug('ContentVersion取得後HeapSize：' + Limits.getHeapSize());
                system.debug('LimitHeapSize：' + Limits.getLimitHeapSize());

                if (String.isNotBlank(sendjson)) {

                    sendjson = sendjson + ',';
                }

                // タイトルを取得
                sendjson = sendjson + cv.Title;
                sendjson = sendjson + '.';

                // ファイルタイプを取得
                sendjson = sendjson + cv.FileType;
                sendjson = sendjson + ',';

                // ファイル内容を取得
                sendjson = sendjson + EncodingUtil.base64Encode(cv.VersionData);
            }

            // RESTサービス呼出
            CMN_DSP_Mulesoft.callPostXASTest(sendjson,TIMEOUT_MS);
        }
    }

}