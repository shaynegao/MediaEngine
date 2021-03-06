IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetClosedInvoices]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetClosedInvoices]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetClosedInvoices]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
        CREATE PROCEDURE [media].[prc_FinanceGetClosedInvoices]
		(
			@PaymentID  bigint = NULL,
			@PlanPayID  bigint = NULL
		)      
        AS
        	SET NOCOUNT ON 
        	
        	
        	CREATE TABLE #t_payment
        	(
        		PaymentID   BIGINT
        	)
        	
        	CREATE TABLE #t_refund
        	(
        		RefundID   BIGINT
        	)
        	
        	IF @PaymentID IS NOT NULL
        		INSERT INTO #t_payment  ( PaymentID ) VALUES (@PaymentID)
			ELSE
				BEGIN
					
					INSERT INTO #t_payment  ( PaymentID )
					SELECT PayBillID FROM media.tbb_PayBill WHERE PlanPayID = @PlanPayID
					
					INSERT INTO #t_refund  ( RefundID )
					SELECT RB.ReturnBillID FROM media.tbb_ReturnBill RB
					JOIN #t_payment P ON RB.PayBillID = P.PaymentID
					
				END
        	
        	SELECT  I.InvoiceID ,
                I.VerifyID ,
                I.InvoiceType ,
                I.InvoiceCode ,
                I.InvoiceNo ,
                I.InvoiceAmount AS ClosedAmount,
                I.VendorName ,
                I.ReceiveDate ,
                I.InvoiceStatus ,
                IT.TaxAmount,
                IT.TaxRate
		 FROM media.tbb_Invoice I
			JOIN media.tbb_Bill_Invoice BI ON BI.VerifyID = I.VerifyID
			LEFT JOIN media.tbi_InvoiceTaxes IT ON I.InvoiceID = IT.InvoiceID
        WHERE I.InvoiceType IN (''INVOICE'', ''VAT_INVOICE'')
        AND I.InvoiceStatus = 10
        AND ((BI.BillType = 0 AND BI.BillID IN( SELECT PaymentID FROM #t_payment))
			OR (BI.BillType = 1 AND BI.BillID IN( SELECT RefundID FROM #t_refund)))
			
			DROP TABLE  #t_payment
			DROP TABLE #t_refund
        	
' 
END
GO
