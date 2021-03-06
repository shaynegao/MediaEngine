IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetInvoiceListByVerify]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetInvoiceListByVerify]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetInvoiceListByVerify]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'





























 

-- =============================================    
-- Author:  gaoweiwei    
-- Create date: 2013-06-18   
-- Description: 根据关联ID得到对应的发票列表（不分页）
-- Return Value:
-- Example: 

CREATE proc [media].[prc_FinanceGetInvoiceListByVerify]
    @VerifyID   BIGINT
as
begin
    set nocount on

    SELECT   I.InvoiceID AS InvoiceSerial,
            VerifyID ,
            InvoiceType ,
            InvoiceCode ,
            InvoiceNo ,
            InvoiceAmount ,
            VendorName  AS InvoicePayeeName,
            ReceiveDate ,
            InvoiceStatus ,
            TaxAmount ,
            TaxRate,
            (InvoiceAmount - TaxAmount) AS ExcludeTaxAmount
            
             FROM media.tbb_Invoice I
            LEFT JOIN media.tbi_InvoiceTaxes IT ON I.InvoiceID = IT.InvoiceID
    WHERE I.VerifyID = @VerifyID
    
end


































' 
END
GO
