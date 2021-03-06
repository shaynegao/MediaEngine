IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceInvoiceBundleVerify]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceInvoiceBundleVerify]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceInvoiceBundleVerify]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceInvoiceBundleVerify] @VerifyID	BIGINT as
SET NOCOUNT ON 
	
	declare @Result varchar(120)

	IF EXISTS (SELECT * FROM media.tbb_Invoice WHERE VerifyID = @VerifyID AND InvoiceStatus <> 5 )
	BEGIN
		SELECT @Result = ''当前状态不允许审核''
	END
	ELSE
	BEGIN
        begin try
			BEGIN TRAN
                    
				UPDATE media.tbb_Invoice
				SET InvoiceStatus = 10
				WHERE VerifyID = @VerifyID
				
				IF EXISTS (SELECT * FROM media.tbb_Invoice WHERE VerifyID = @VerifyID AND InvoiceType LIKE ''%INVOICE%'' )
				BEGIN
					UPDATE PB
					SET PB.CloseAmount = PB.CloseAmount + BI.CloseAmount
					FROM media.tbb_Bill_Invoice BI
					JOIN media.tbb_PayBill PB ON BI.BillID = PB.PayBillID
					WHERE BI.VerifyID = @VerifyID AND  BI.BillType = 0
					
					UPDATE RB
					SET RB.CloseAmount = RB.CloseAmount + BI.CloseAmount
					FROM media.tbb_Bill_Invoice BI
					JOIN media.tbb_ReturnBill RB ON BI.BillID = RB.ReturnBillID
					WHERE BI.VerifyID = @VerifyID AND  BI.BillType = 1
					
					IF EXISTS (SELECT *  FROM media.tbb_Bill_Invoice BI
					JOIN media.tbb_PayBill PB ON BI.BillID = PB.PayBillID
					WHERE BI.VerifyID = @VerifyID AND  BI.BillType = 0 AND PB.CloseAmount > PB.PayAmount)
					BEGIN
						RAISERROR(''overflow'', 16, 1)
					END 	
						
					IF EXISTS (SELECT *  FROM media.tbb_Bill_Invoice BI
					JOIN media.tbb_ReturnBill RB ON BI.BillID = RB.ReturnBillID
					WHERE BI.VerifyID = @VerifyID AND  BI.BillType = 1 AND RB.CloseAmount > RB.ReturnAmount)
					BEGIN
						RAISERROR(''overflow'', 16, 1)
					END 	
				
					
				END 
				COMMIT TRAN
                select @Result = ''OK''
            end try
                    
            begin catch
                rollback tran
                select @Result = ''更新时发生异常''
            end catch;

	END
	
	select @Result as ''Result''
' 
END
GO
