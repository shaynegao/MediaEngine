IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPaymentDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPaymentDetail]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPaymentDetail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPaymentDetail] (
     @PaymentID      bigint
 ) as
begin
    set nocount on

    select 
    PB.PayBillID as ID
    , PB.PayAmount as ActualPayAmount
    , PB.PayKind as ActualPayMethod
    , PB.PayDate as ActualPayDate
    , PB.PlanPayID as PlanPayID
    , PA.AccountName as ActualPayeeName
    , PA.AccountBank as ActualPayeeBankName
    , PA.AccountNumber as ActualPayeeAccountNumber
    , PAA.ApplyDate
    , PAA.AuditStatus
    , U1.UserName AS ApplyUserName
    , U2.UserName AS AuditUserName
    , PAA.AuditTime
    , PB.ReturnAmount AS RefundAmount
    , PB.LastUpdateTime AS LastUpdateTime
	 from  media.tbb_PayBill PB
	 JOIN media.tbb_PayApply PAA ON PB.PayBillID = PAA.PayBillID
	 left join media.tbi_PayAccount PA on PB.PayBillID = PA.PayBillID
	 LEFT JOIN basic.tbb_User U1 ON PAA.ApplyUserID = U1.UserID
	 LEFT JOIN basic.tbb_User U2 ON PAA.AuditUserID = U2.UserID
    where PB.PayBillID = @PaymentID
    
end
' 
END
GO
