IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPaymentRequestDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPaymentRequestDetail]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPaymentRequestDetail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
-- =============================================
-- Author:  gaoweiwei
-- Create date: 2013-11-15
-- Description: 查询付款申请
-- Return Value:
-- Example:
CREATE proc [media].[prc_FinanceGetPaymentRequestDetail]
(
    @PaymentRequestID      bigint
)
as
begin
    set nocount on

    select 
    PA.PayBillID as ID
    , PA.PayAmount as PayAmount
    , PA.PayKind as PayMethod
    , PA.PlanPayID as PlanPayID
    , PAA.AccountName as PayeeName
    , PAA.AccountBank as PayeeBankName
    , PAA.AccountNumber as PayeeAccountNumber
    , PA.ApplyDate
    , PA.AuditStatus
    , U1.UserName AS ApplyUserName
    , U2.UserName AS AuditUserName
    , PA.AuditTime
    , PA.LastUpdateTime AS LastUpdateTime
     from  media.tbb_PayApply PA
     left join media.tbi_PayAccount PAA on PA.PayBillID = PAA.PayBillID
     LEFT JOIN basic.tbb_User U1 ON PA.ApplyUserID = U1.UserID
     LEFT JOIN basic.tbb_User U2 ON PA.AuditUserID = U2.UserID
    where PA.PayBillID = @PaymentRequestID
    

end

' 
END
GO
