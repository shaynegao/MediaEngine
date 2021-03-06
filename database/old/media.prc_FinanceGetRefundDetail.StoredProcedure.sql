IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetRefundDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetRefundDetail]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetRefundDetail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'




































-- =============================================
-- Author:  gaoweiwei
-- Create date: 2013-05-23
-- Description: 查询退款明细
-- Return Value:
-- Example:
CREATE proc [media].[prc_FinanceGetRefundDetail]
(
    @RefundID      bigint
)
as
begin
    set nocount ON
    
    SELECT  RB.ReturnBillID AS RefundID,
       -- PayBillID ,
        RB.ReturnKind AS PayMethod,
        RB.ReturnAmount AS Amount ,
        RB.ReturnDate AS RefundDate,
        RB.ValidStatus AS AuditStatus,
     --   CloseAmount ,
        RB.ReturnReason AS RefundReason,
      --  CreateTime ,
        RB.LastUpdateTime AS LastUpdateTime,
        RA.AccountBank AS RefundBankName,
        RA.AccountName AS RefundName,
        RA.AccountNumber AS RefundAccountNumber
               
    FROM media.tbb_ReturnBill RB
           LEFT JOIN media.tbi_ReturnAccount RA ON RB.ReturnBillID = RA.ReturnBillID
    WHERE RB.ReturnBillID = @RefundID

end




 















' 
END
GO
